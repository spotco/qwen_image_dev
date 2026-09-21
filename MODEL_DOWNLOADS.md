# Qwen Image 2.1 local model files

Large model binaries are intentionally not stored in this Git repository and Git LFS is not used.

Download these official Comfy-Org files from Hugging Face and place them under `ComfyUI_source\models`:

| File | Destination | Official URL |
| --- | --- | --- |
| `qwen_image_2.1_int8_convrot.safetensors` | `models\diffusion_models` | https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/diffusion_models/qwen_image_2.1_int8_convrot.safetensors |
| `qwen3vl_8b_w4a8.safetensors` | `models\text_encoders` | https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/text_encoders/qwen3vl_8b_w4a8.safetensors |
| `qwen_image_2.1_vae_bf16.safetensors` | `models\vae` | https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/vae/qwen_image_2.1_vae_bf16.safetensors |

The launcher uses the embedded Python runtime from `ComfyUI_windows_portable\python_embeded` and the source checkout from `ComfyUI_source`. The launcher passes `--base-directory ComfyUI_source`, so the model files must be in the source checkout's model directories.

The tracked workflow is configured for the INT8 ConvRot transformer, W4A8 text encoder, matching VAE, 1024x1024, 25 steps, Euler/simple sampling, batch size 1, DynamicVRAM, and async offload.
