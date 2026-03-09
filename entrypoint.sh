#!/bin/bash
set -e

# ── CUDA checks (keep as-is) ───────────────────────────────

# ── Network Volume ─────────────────────────────────────────
VOLUME_PATH="/runpod-volume/models"
COMFY_PATH="/ComfyUI"

# Serverless: volume may take a moment to mount
echo "Waiting for network volume..."
max_vol_wait=60
vol_count=0
until [ -d "$VOLUME_PATH" ] || [ $vol_count -ge $max_vol_wait ]; do
    sleep 2
    vol_count=$((vol_count + 2))
done

if [ ! -d "$VOLUME_PATH" ]; then
    echo "❌ Network volume not mounted at $VOLUME_PATH after ${max_vol_wait}s"
    exit 1
fi
echo "✅ Network volume ready"

# Write model paths config
cat > "$COMFY_PATH/extra_model_paths.yaml" <<EOF
comfyui:
    base_path: $VOLUME_PATH
    diffusion_models: diffusion_models/
    text_encoders: text_encoders/
    vae: vae/
    loras: loras/
    upscale_models: upscale_models/
EOF

# Fast model check (skip slow find, just stat)
REQUIRED_MODELS=(
    "diffusion_models/qwen_image_edit_2511_fp8mixed.safetensors"
    "vae/qwen_image_vae.safetensors"
    "text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors"
    "loras/Qwen-Image-Edit-2511-Lightning-4steps-V1.0-bf16.safetensors"
    "upscale_models/RealESRGAN_x2plus.pth"
)
for model in "${REQUIRED_MODELS[@]}"; do
    if [ ! -f "$VOLUME_PATH/$model" ]; then
        echo "❌ Missing: $VOLUME_PATH/$model"
        exit 1
    fi
done
echo "✅ All models verified"
# ───────────────────────────────────────────────────────────

echo "Starting ComfyUI..."
python $COMFY_PATH/main.py --listen --use-sage-attention &
# ... rest of your script
```

**Serverless-specific setup in RunPod console:**
```
Endpoint Settings → Network Volume → attach your volume
                 → Volume Mount Path: /runpod-volume  ← must match