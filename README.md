# **🚀 ComfyUI ROCm Enterprise Container (RDNA4 / RX 9070 XT)**

**⚠️ Project Status: Alpha Phase**

This project is currently in early testing (v0.1.x) specifically tailored for bleeding-edge RDNA4 hardware. While highly optimized, you may encounter edge cases. Feedback, issues, and contributions are highly welcome\!

A professional-grade, ultra-resilient Docker environment for running **ComfyUI** on AMD hardware, specifically optimized for the **RDNA4 (RX 9070 XT / gfx1201)** architecture.

## **✨ Key Features**

* 📦 **Auto-Bootstrap ComfyUI-Manager:** Automatically installs the official ComfyUI-Manager on your first launch. You get an instant, fully functional graphical interface to install models, custom nodes, and updates without touching the terminal.  
* 🛡️ **Dependency Shield:** A strict constraints system that prevents Custom Nodes from installing NVIDIA or CPU-compatible PyTorch versions, safeguarding your ROCm environment.  
* ⚡ **Extreme Speed:** Optimized installations and HuggingFace model downloads tailored for maximum bandwidth utilizing hf\_transfer and uv package manager.  
* 💾 **Total Persistence:** Models, workflows, UI configurations, and even **hidden caches** are safely stored on your local drive. No data is lost if the container is destroyed or rebuilt.  
* 🧠 **Advanced Memory Management:** Includes jemalloc injection to prevent memory leaks and fragmentation (OOM errors) during extended generation sessions.  
* 🐳 **GitHub Container Registry (GHCR):** Pre-built images are automatically hosted on GHCR, allowing users to run the environment instantly without building from scratch.

## **📂 Project Structure & Volumes**

Upon execution, the following directories will be created on your host system. **Please place your downloaded models in their respective subdirectories within models/**:

* models/: Checkpoints, LoRAs, ControlNets, VAEs.  
* output/: Generated images and videos.  
* custom\_nodes/: ComfyUI extensions and plugins (including the auto-installed ComfyUI-Manager).  
* user/: Saved UI configurations and workflows.  
* cache/: (Hidden) Persistent cache for temporary downloads (e.g., HuggingFace hub, YOLO models).

## **🚀 Installation & Usage**

### **1\. Clone the repository**

git clone \[https://github.com/alvjtc/comfyui-rocm-rx9070xt.git\](https://github.com/alvjtc/comfyui-rocm-rx9070xt.git)  
cd comfyui-rocm-rx9070xt

### **2\. Grant execution permissions**

chmod \+x comfy.sh start.sh

### **3\. Launch ComfyUI**

An interactive script (comfy.sh) is provided to adjust PyTorch memory allocation based on your current generation needs:

\# For image generation (Flux, SDXL)  
./comfy.sh photo

\# For video generation (Wan2.1, LTX-Video)  
./comfy.sh video

\# For advanced mode utilizing SageAttention  
./comfy.sh video-sage

### **🛠️ Maintenance Mode (Updates)**

To update the ComfyUI core source code and the dependencies of all your installed *Custom Nodes*, simply append the \--update flag:

./comfy.sh photo \--update

## **🐳 Running Pre-built Images from GHCR**

This repository automatically builds and publishes Docker images to the GitHub Container Registry. If you prefer not to build the image locally, you can pull it directly:

1. Ensure the image: line in your docker-compose.yml points to this repository:  
   image: ghcr.io/alvjtc/comfyui-rocm-rx9070xt:latest  
2. Run your preferred launch command (e.g., ./comfy.sh photo). Docker will automatically download the pre-built, optimized environment.

## **📝 License**

Distributed under the MIT License. See the LICENSE file for more information.