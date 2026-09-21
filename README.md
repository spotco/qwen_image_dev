# qwen_image_dev

Local Qwen Image 2.1 setup for an 8 GB RTX 4060 Laptop GPU on Windows 11.

## Runtime

- ComfyUI source checkout: `ComfyUI_source`
- Portable embedded Python/CUDA runtime: `ComfyUI_windows_portable\python_embeded`
- Launcher: `run_comfyui_qwen_image.bat`
- Workflow: `qwen21_text_to_image_workflow.json`
- Generated images: `ComfyUI_source\output`

The project uses the official Comfy-Org Qwen Image 2.1 INT8 ConvRot transformer, Qwen3-VL 8B W4A8 text encoder, and BF16 VAE. It is configured for DynamicVRAM and two-stream async offload. It is not a full BF16 model resident in VRAM.

## Run

1. Make sure other GPU applications are closed and most of the 8 GB VRAM is free.
2. Double-click `run_comfyui_qwen_image.bat`.
3. Open `http://127.0.0.1:8188` if the browser does not open automatically.
4. Load `qwen21_text_to_image_workflow.json` or use the Qwen Image 2.1 text-to-image template.
5. Edit the prompt and click Run.

The launcher intentionally does not use `--lowvram`, `--highvram`, `--gpu-only`, or `--disable-smart-memory`. It reserves 1 GB of VRAM for the desktop and enables DynamicVRAM with two async offload streams.

## Model files

See [MODEL_DOWNLOADS.md](MODEL_DOWNLOADS.md). Model binaries and the local ComfyUI installation are ignored by Git.

## Updating ComfyUI

`ComfyUI_source` is a separate Git checkout and is intentionally not vendored into this project repository. Update it independently, then re-run the smoke test through the launcher.
