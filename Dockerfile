FROM rocm/pytorch:rocm7.2_ubuntu24.04_py3.12_pytorch_release_2.9.1

LABEL maintainer="alvjtc" \
    description="Optimized ComfyUI Container for AMD ROCm (RDNA4 / RX 9070 XT)" \
    repository="https://github.com/alvjtc/comfyui-rocm-rx9070xt" \
    version="0.1.1-alpha"

# System configuration & Environment Variables
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_ROOT_USER_ACTION=ignore \
    ROCM_PATH=/opt/rocm \
    COMFY_ARGS="" \
    PATH="/opt/venv/bin:$PATH" \
    HF_HUB_ENABLE_HF_TRANSFER=1

# Architecture targeting for AMD RX 9070 XT (RDNA4)
# Forces JIT compilations to target this specific hardware natively.
ARG ROCM_ARCH="gfx1201"
ENV PYTORCH_ROCM_ARCH=${ROCM_ARCH}

# System dependencies required for compiling extensions (gcc, ninja)
# media processing (libgl1, ffmpeg), and memory management (libjemalloc2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git libgl1 libglib2.0-0 ffmpeg libsm6 libxext6 nano \
    gcc g++ ninja-build libjemalloc2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Inject jemalloc to prevent memory fragmentation and leaks in PyTorch
# (Placed AFTER installation to prevent ld.so errors during build)
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

WORKDIR /workspace

# Generate strict constraints based on the official AMD pre-installed packages.
# This prevents external node requirements from overwriting ROCm-specific PyTorch binaries.
RUN pip freeze | grep -E "^(torch|torchvision|torchaudio|triton|pytorch-triton-rocm|numpy)==" > /tmp/rocm_constraints.txt

# ========================================================================
# PYTHON DEPENDENCIES (Using standard pip for maximum compatibility with AMD wheels)
# ========================================================================

# Group A: Core AI, Math, and HuggingFace ecosystem
RUN pip install --no-cache-dir -c /tmp/rocm_constraints.txt \
    packaging ninja toml GitPython dill iopath hf-transfer uv \
    einops safetensors torchsde hydra-core bitsandbytes optimum peft \
    accelerate diffusers transformers gguf rotary-embedding-torch

# Group B: Computer Vision, Image, and Video processing
RUN pip install --no-cache-dir -c /tmp/rocm_constraints.txt \
    opencv-contrib-python-headless scikit-image ftfy matplotlib pandas \
    insightface ultralytics blend-modes piexif qwen-vl-utils surrealist \
    imageio-ffmpeg moviepy sageattention==1.0.6 onnxruntime-rocm

# Group C: Audio and Document processing
RUN pip install --no-cache-dir -c /tmp/rocm_constraints.txt \
    librosa pyloudnorm pypdf2 pdf2image pymupdf reportlab

# Group D: Cloud APIs and External Services
RUN pip install --no-cache-dir -c /tmp/rocm_constraints.txt \
    boto3 fal-client openai ollama google-genai google-cloud-storage runwayml redis replicate

# ========================================================================

# Install SAM2 directly from repository
RUN pip install --no-cache-dir -c /tmp/rocm_constraints.txt --no-deps "git+https://github.com/facebookresearch/sam2.git"

# Clone and initialize ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
WORKDIR /workspace/ComfyUI

# Install base ComfyUI requirements, explicitly filtering out incompatible CUDA/CPU packages
RUN grep -iE -v "torch|torchvision|torchaudio|triton|numpy|cupy|nvidia|flash-attn" requirements.txt > requirements_safe.txt && \
    pip install --no-cache-dir -c /tmp/rocm_constraints.txt -r requirements_safe.txt

EXPOSE 8188

# Entrypoint is managed via docker-compose.yml