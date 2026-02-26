#!/bin/bash
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BASE_ALLOC="expandable_segments:True,garbage_collection_threshold:0.8,max_split_size_mb:256"

export COMFY_UPDATE="false"

# Check for update flag
if [[ "$*" == *"--update"* ]]; then
  export COMFY_UPDATE="true"
  echo -e "${YELLOW}[SYSTEM] Maintenance mode flagged. Repositories and dependencies will be updated on startup.${NC}"
fi

# Extract execution mode
MODE=$(echo "$@" | sed 's/--update//g' | xargs)

case $MODE in
  photo)
    echo -e "${BLUE}[CONFIG] Starting PHOTO MODE (Flux/SDXL optimized)${NC}"
    export PYTORCH_HIP_ALLOC_CONF="$BASE_ALLOC"
    export COMFY_ARGS="--normalvram --fp8_e4m3fn-text-enc --preview-method latent2rgb"
    ;;
  video)
    echo -e "${BLUE}[CONFIG] Starting VIDEO MODE (Wan2.1/LTX/SVD - High Precision)${NC}"
    export PYTORCH_HIP_ALLOC_CONF="max_split_size_mb:512"
    export COMFY_ARGS="--lowvram --preview-method latent2rgb"
    ;;
  video-sage)
    echo -e "${GREEN}[CONFIG] Starting SAGE ATTENTION MODE${NC}"
    export PYTORCH_HIP_ALLOC_CONF="$BASE_ALLOC"
    export COMFY_ARGS="--normalvram --use-sage-attention --preview-method latent2rgb"
    ;;
  *)
    echo -e "${RED}[ERROR] Invalid or missing mode.${NC}"
    echo "Usage: ./comfy.sh [photo|video|video-sage] [--update]"
    echo "Example: ./comfy.sh photo --update"
    exit 1
    ;;
esac

# Architecture identifier for container runtime
export HSA_OVERRIDE_GFX_VERSION="12.0.0"

# Recreate and start the container
docker compose down --remove-orphans
docker compose up -d

echo -e "${GREEN}[SUCCESS] Container started. To view logs run: docker compose logs -f${NC}"