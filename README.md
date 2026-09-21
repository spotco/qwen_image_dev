# qwen_image_dev

Local Qwen Image 2.1 setup for an 8 GB RTX 4060 Laptop GPU on Windows 11.

## Runtime

- ComfyUI source checkout: `ComfyUI_source`
- Portable embedded Python/CUDA runtime: `python_embeded`
- Launcher: `run_comfyui_qwen_image.bat`
- Workflow: `qwen21_text_to_image_workflow.json`
- Workflow pack: the six `qwen21_*_workflow.json` files listed below
- Generated images: `ComfyUI_source\output`
- Background-removal model: `ComfyUI_source\models\background_removal\birefnet.safetensors`

The project uses the official Comfy-Org Qwen Image 2.1 INT8 ConvRot transformer, Qwen3-VL 8B W4A8 text encoder, and BF16 VAE. It is configured for DynamicVRAM and two-stream async offload. It is not a full BF16 model resident in VRAM. The background-removal workflow additionally uses the official Comfy-Org BiRefNet model for reliable alpha masks.

## Run

1. Make sure other GPU applications are closed and most of the 8 GB VRAM is free.
2. Double-click `run_comfyui_qwen_image.bat`.
3. Open `http://127.0.0.1:8188` if the browser does not open automatically.
4. Load `qwen21_text_to_image_workflow.json` or use the Qwen Image 2.1 text-to-image template.
5. Edit the prompt and click Run.

The launcher intentionally does not use `--lowvram`, `--highvram`, `--gpu-only`, or `--disable-smart-memory`. It reserves 1 GB of VRAM for the desktop and enables DynamicVRAM with two async offload streams.

## Workflow pack

- [qwen21_text_to_image_workflow.json](qwen21_text_to_image_workflow.json) — baseline 1024x1024 text-to-image.
- [qwen21_image_modification_workflow.json](qwen21_image_modification_workflow.json) — modify `image1` with a text prompt and optional `image2` reference.
- [qwen21_image_combine_workflow.json](qwen21_image_combine_workflow.json) — combine two images; use `<image1>` and `<image2>` in the prompt to control their roles.
- [qwen21_inpainting_workflow.json](qwen21_inpainting_workflow.json) — Qwen edit candidate plus masked compositing; white in `qwen21_inpaint_mask.png` is regenerated and the original is preserved elsewhere.
- [qwen21_background_removal_workflow.json](qwen21_background_removal_workflow.json) — native BiRefNet mask plus RGBA PNG output. This workflow requires the documented BiRefNet model.
- [qwen21_style_transfer_workflow.json](qwen21_style_transfer_workflow.json) — preserve `image1` content while using `image2` as a watercolor animation style reference.

The sample inputs used for validation are local files under `ComfyUI_source\input` and are ignored by Git. Change the `LoadImage`/`LoadImageMask` nodes to use your own images.

## Validation status

The four workflows were loaded and queued through the running ComfyUI UI with Brave DevTools. Successful outputs were written to `ComfyUI_source\output`:

- `Qwen21_image_modification_00001.png`
- `Qwen21_image_combine_00001.png`
- `Qwen21_inpaint_00001.png`
- `Qwen21_background_removed_00001_.png` (confirmed RGBA with transparency)
- `Qwen21_style_transfer_00001.png`

## Fresh-clone setup

See [DOWNLOAD_SETUP.md](DOWNLOAD_SETUP.md) for the complete setup and authoritative model list: official project and binary links, PowerShell download commands, model destinations, launcher settings, validation, and troubleshooting. Any model downloaded for a tracked workflow must be documented there. Model binaries and the local ComfyUI installation are ignored by Git.

## Updating ComfyUI

`ComfyUI_source` is a separate Git checkout and is intentionally not vendored into this project repository. Update it independently, then re-run the smoke test through the launcher.
