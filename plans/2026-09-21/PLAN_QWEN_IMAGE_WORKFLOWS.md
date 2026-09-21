# Qwen Image 2.1 Workflow Pack Plan

Date: 2026-09-21
Status: Implemented; validated and pushed
Branch: `main`
Scope: one implementation day

## Progress

- [x] Step 1 - Read the reference plan and confirm the ComfyUI/Qwen contracts
- [x] Step 2 - Confirm native image-edit, multi-image, mask/composite, and background-removal nodes
- [x] Step 3 - Add the official BiRefNet download to the setup documentation
- [x] Step 4 - Add `qwen21_image_modification_workflow.json`
- [x] Step 5 - Add `qwen21_image_combine_workflow.json`
- [x] Step 6 - Add `qwen21_inpainting_workflow.json`
- [x] Step 7 - Add `qwen21_background_removal_workflow.json`
- [x] Step 8 - Prepare local input assets and an explicit inpainting mask
- [x] Step 9 - Move the embedded Python runtime to the project root and update the launcher
- [x] Step 10 - Load and validate all four workflows through ComfyUI in Brave
- [x] Step 11 - Confirm outputs, model selection, VRAM behavior, and saved files
- [x] Step 12 - Update documentation with usage instructions and validation results
- [x] Step 13 - Commit and push the completed workflow pack

## Objective

Add four importable ComfyUI workflows for the tested Qwen Image 2.1 stack:

1. mask-guided inpainting with text instruction;
2. alpha background removal;
3. text-guided modification of an input image;
4. combining two images with explicit `<image1>` / `<image2>` prompt control.

All Qwen workflows use the installed INT8 ConvRot transformer, W4A8 text encoder, BF16 VAE, 1024-class target sizing, and the existing DynamicVRAM launcher. Background removal uses native ComfyUI BiRefNet because Qwen generation alone does not guarantee a reliable alpha channel.

## Constraints and invariants

- Keep model files out of Git and out of Git LFS.
- Document every downloaded model in `DOWNLOAD_SETUP.md` and keep `README.md` pointed at that authoritative list.
- Use native ComfyUI nodes and official workflow-template patterns where available.
- Test by loading each JSON in the running ComfyUI UI through Brave MCP.
- Use local input assets only; do not upload project images to third parties.
- Keep the root-level `python_embeded` runtime and `ComfyUI_source` paths consistent between the launcher and documentation.
- Preserve the existing tested text-to-image workflow.

## Design notes

### Inpainting

Qwen Image 2.1’s official edit path is reference-image based rather than a dedicated mask node. The workflow generates an edit candidate from the input image and prompt, then `ImageCompositeMasked` keeps the original image outside the white-on-black mask. Replace `qwen21_inpaint_mask.png` or edit the mask input to change the highlighted region.

### Background removal

The workflow follows Comfy-Org’s official BiRefNet template and saves an RGBA PNG through `JoinImageWithAlpha` and `SaveImage`. The required model is `ComfyUI_source\models\background_removal\birefnet.safetensors` and is documented in `DOWNLOAD_SETUP.md`.

### Image modification and combining

Both workflows use the official Qwen Image 2.1 image-edit subgraph. The first loaded image is the base/edit target and the second is an optional reference. Prompts explicitly name the images using `<image1>` and `<image2>` so the user can customize composition, subject, style, and placement.

## Validation commands

```powershell
Get-Content -Raw .\qwen21_inpainting_workflow.json | ConvertFrom-Json | Out-Null
Get-Content -Raw .\qwen21_background_removal_workflow.json | ConvertFrom-Json | Out-Null
Get-Content -Raw .\qwen21_image_modification_workflow.json | ConvertFrom-Json | Out-Null
Get-Content -Raw .\qwen21_image_combine_workflow.json | ConvertFrom-Json | Out-Null
nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv
```

## Validation results

- [x] Image modification completed: `Qwen21_image_modification_00001.png`.
- [x] Image combining completed: `Qwen21_image_combine_00001.png`.
- [x] Mask-guided inpainting completed: `Qwen21_inpaint_00001.png`.
- [x] Background removal completed with an RGBA result: `Qwen21_background_removed_00001_.png`.
- [x] The background-removal output was checked as a 1024x1024 RGBA PNG with transparent pixels.
- [x] The launcher was restarted from the root-level `python_embeded` runtime with DynamicVRAM and async offload enabled.

Manual Brave validation must queue one prompt for each workflow and verify the output appears in `ComfyUI_source\output`.
