#!/bin/bash
set -e

# Environment protection and constraints
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
export PIP_CONSTRAINT=/tmp/rocm_constraints.txt
export DISABLE_CUPY=1

# Force external tools (like uv and Manager) to use the correct Python virtual environment
export VIRTUAL_ENV="/opt/venv"
export PATH="/opt/venv/bin:$PATH"

cd /workspace/ComfyUI

# ---------------------------------------------------------
# Core Extensions Bootstrap
# Installs essential nodes like ComfyUI-Manager on first run
# ---------------------------------------------------------
if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    echo "[INFO] ComfyUI-Manager not found in volume. Bootstrapping installation..."
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
    if [ -f "custom_nodes/ComfyUI-Manager/requirements.txt" ]; then
        pip install --no-cache-dir -c /tmp/rocm_constraints.txt -r custom_nodes/ComfyUI-Manager/requirements.txt || true
    fi
fi

# Maintenance mode: Updates ComfyUI and custom nodes dependencies
if [ "$COMFY_UPDATE" == "true" ]; then
    echo "[INFO] Maintenance mode activated. Updating ComfyUI core..."
    git pull || echo "[WARN] Failed to pull ComfyUI core repository."
    
    echo "[INFO] Checking and updating custom nodes..."
    if [ -d "custom_nodes" ]; then
        for node_dir in custom_nodes/*/; do
            if [ -d "$node_dir/.git" ]; then
                echo "[INFO] Updating node: $(basename "$node_dir")"
                (cd "$node_dir" && git pull || true)
            fi

            if [ -f "${node_dir}requirements.txt" ]; then
                echo "[INFO] Processing dependencies for: $(basename "$node_dir")"
                # Filter out incompatible CUDA/CPU packages
                grep -iE -v "torch|cupy|nvidia|flash-attn" "${node_dir}requirements.txt" > "${node_dir}requirements_safe.txt" || true
                
                # Install dependencies using pip with rocm constraints
                pip install --no-cache-dir -c /tmp/rocm_constraints.txt -r "${node_dir}requirements_safe.txt" || echo "[ERROR] Dependency installation failed for $(basename "$node_dir")"
            fi
        done
    fi
    
    # Cleanup package cache
    pip cache purge || true
    echo "[INFO] Maintenance completed successfully."
fi

# Ensure all pending disk writes (like newly pulled nodes) are physically flushed
sync

# Standard execution
echo "[INFO] Launching ComfyUI..."
exec python main.py ${CLI_ARGS}