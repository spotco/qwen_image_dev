# Qwen Image 2.1 fresh-clone setup

This document is the complete setup guide for this repository on Windows 11 with an NVIDIA RTX 4060 Laptop GPU (8 GB VRAM) and substantial system RAM.

The target is **quantized inference with ComfyUI DynamicVRAM and CPU/RAM offload**. It is not a full BF16 model resident in VRAM.

## 1. Architecture and what is tracked

The repository contains the small, reproducible project files:

```text
qwen_image_dev\
├── DOWNLOAD_SETUP.md
├── README.md
├── .gitignore
├── run_comfyui_qwen_image.bat
├── qwen21_text_to_image_workflow.json
├── qwen21_image_modification_workflow.json
├── qwen21_image_combine_workflow.json
├── qwen21_inpainting_workflow.json
└── qwen21_background_removal_workflow.json
```

The large runtime and model files are downloaded locally and are deliberately not committed or stored with Git LFS:

```text
qwen_image_dev\
├── ComfyUI_source\                  # separate ComfyUI Git checkout
│   └── models\
│       ├── diffusion_models\        # Qwen Image transformer
│       ├── text_encoders\           # Qwen3-VL text encoder
│       ├── vae\                     # Qwen Image VAE
│       └── background_removal\      # BiRefNet alpha-mask model
└── python_embeded\                  # embedded Python/CUDA runtime
    └── python.exe
```

The launcher intentionally runs the source checkout with the root-level embedded Python. The source checkout is required because the Qwen Image 2.1 nodes are provided by current native ComfyUI support.

### Official project links

- This project: <https://github.com/spotco/qwen_image_dev>
- ComfyUI source: <https://github.com/Comfy-Org/ComfyUI>
- ComfyUI workflow templates: <https://github.com/Comfy-Org/workflow_templates>
- Official Qwen Image 2.1 text-to-image template: <https://github.com/Comfy-Org/workflow_templates/blob/main/templates/image_qwen_image_2_1_t2i.json>
- Official Qwen Image 2.1 Comfy-Org model repository: <https://huggingface.co/Comfy-Org/Qwen-Image-2.1>
- Original Qwen Image 2.1 model card: <https://huggingface.co/Qwen/Qwen-Image-2.1>

### Official runtime and utility downloads

- NVIDIA Windows portable ComfyUI archive: <https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z>
- ComfyUI release page: <https://github.com/Comfy-Org/ComfyUI/releases/latest>
- 7-Zip: <https://www.7-zip.org/download.html>

The NVIDIA portable archive supplies an independent Python environment and CUDA-enabled PyTorch. Do not mix it with a system Python installation for this setup.

## 2. Hardware target and model choice

This setup uses:

- `qwen_image_2.1_int8_convrot.safetensors`: INT8 ConvRot diffusion transformer
- `qwen3vl_8b_w4a8.safetensors`: Qwen3-VL 8B W4A8 text encoder
- `qwen_image_2.1_vae_bf16.safetensors`: matching BF16 VAE
- `birefnet.safetensors`: official ComfyUI BiRefNet model used by the native background-removal workflow
- 1024x1024, 25 steps, batch size 1
- DynamicVRAM and two-stream asynchronous offload

INT8 is the recommended first choice here. The INT8 transformer is more practical than full BF16 on an 8 GB GPU, while the W4A8 text encoder keeps the text-encoding side small enough for RAM/VRAM streaming. INT4 may reduce memory further if an official compatible file is available, but it is not the tested project configuration and should not be the starting point.

Before every first-generation test, close other GPU-heavy applications, including `llama-server`, and check the GPU:

```powershell
nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv
```

For this 8188 MiB GPU, aim for at least **6 GiB free**, preferably **7 GiB or more**, before queuing the first image. A previous state with only 214 MiB free is not usable for this workflow.

## 3. Fresh-clone installation

Use a local SSD if possible. The three Qwen model files occupy roughly 14 GB; BiRefNet adds roughly 0.4 GB, and the ComfyUI runtime/source checkout needs additional space.

### 3.1 Clone this project

Choose a directory with enough free space, then run:

```powershell
Set-Location E:\
git clone https://github.com/spotco/qwen_image_dev.git qwen_image_dev
Set-Location E:\qwen_image_dev
```

If the repository is already cloned, update only the project files with:

```powershell
git pull --ff-only
```

### 3.2 Download and extract the official NVIDIA portable runtime

Download the official archive:

```powershell
Set-Location E:\qwen_image_dev
curl.exe -L --fail --retry 5 --retry-delay 5 -C - -o .\ComfyUI_windows_portable_nvidia.7z https://github.com/comfyanonymous/ComfyUI/releases/latest/download/ComfyUI_windows_portable_nvidia.7z
```

Extract it with 7-Zip. This command assumes the normal 7-Zip installation path:

```powershell
& 'C:\Program Files\7-Zip\7z.exe' x .\ComfyUI_windows_portable_nvidia.7z '-o.' -y
```

If 7-Zip is installed elsewhere, use its `7z.exe` path. Move the embedded runtime out of the archive wrapper:

```powershell
Move-Item .\ComfyUI_windows_portable\python_embeded .\python_embeded
```

The active runtime must then be:

```text
E:\qwen_image_dev\python_embeded\python.exe
```

Do not place the archive, extracted runtime, or model files inside the Git repository's tracked history. They are ignored by `.gitignore`.

### 3.3 Clone ComfyUI source separately

From the project root:

```powershell
git clone https://github.com/Comfy-Org/ComfyUI.git .\ComfyUI_source
```

Install/update dependencies using the embedded Python from the portable runtime:

```powershell
$py = (Resolve-Path .\python_embeded\python.exe).Path
& $py -m pip install -r .\ComfyUI_source\requirements.txt
```

Confirm that the runtime is the one being used:

```powershell
& $py -c "import sys, torch; print(sys.executable); print(sys.version); print(torch.__version__); print(torch.version.cuda); print(torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CUDA unavailable')"
```

Expected characteristics are embedded Python 3.13, CUDA-enabled PyTorch, `True` for CUDA availability, and an RTX 4060 Laptop GPU. The exact patch versions may change as the official portable build is updated.

## 4. Download the exact model files

Create the destination directories:

```powershell
New-Item -ItemType Directory -Force .\ComfyUI_source\models\diffusion_models | Out-Null
New-Item -ItemType Directory -Force .\ComfyUI_source\models\text_encoders | Out-Null
New-Item -ItemType Directory -Force .\ComfyUI_source\models\vae | Out-Null
```

Download the official Comfy-Org files. `curl.exe -C -` allows a partially completed download to resume:

```powershell
$downloads = @(
    [pscustomobject]@{
        Url = 'https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/diffusion_models/qwen_image_2.1_int8_convrot.safetensors'
        Path = '.\ComfyUI_source\models\diffusion_models\qwen_image_2.1_int8_convrot.safetensors'
    },
    [pscustomobject]@{
        Url = 'https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/text_encoders/qwen3vl_8b_w4a8.safetensors'
        Path = '.\ComfyUI_source\models\text_encoders\qwen3vl_8b_w4a8.safetensors'
    },
    [pscustomobject]@{
        Url = 'https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/vae/qwen_image_2.1_vae_bf16.safetensors'
        Path = '.\ComfyUI_source\models\vae\qwen_image_2.1_vae_bf16.safetensors'
    },
    [pscustomobject]@{
        Url = 'https://huggingface.co/Comfy-Org/BiRefNet/resolve/main/background_removal/birefnet.safetensors'
        Path = '.\ComfyUI_source\models\background_removal\birefnet.safetensors'
    }
)

foreach ($download in $downloads) {
    Write-Host "Downloading $($download.Path)"
    curl.exe -L --fail --retry 5 --retry-delay 5 -C - -o $download.Path $download.Url
    if ($LASTEXITCODE -ne 0) {
        throw "Download failed: $($download.Url)"
    }
}
```

The exact files, source URLs, and destinations are:

| File | Official source | Destination under this project |
| --- | --- | --- |
| `qwen_image_2.1_int8_convrot.safetensors` | <https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/diffusion_models/qwen_image_2.1_int8_convrot.safetensors> | `ComfyUI_source\models\diffusion_models` |
| `qwen3vl_8b_w4a8.safetensors` | <https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/text_encoders/qwen3vl_8b_w4a8.safetensors> | `ComfyUI_source\models\text_encoders` |
| `qwen_image_2.1_vae_bf16.safetensors` | <https://huggingface.co/Comfy-Org/Qwen-Image-2.1/resolve/main/vae/qwen_image_2.1_vae_bf16.safetensors> | `ComfyUI_source\models\vae` |
| `birefnet.safetensors` | <https://huggingface.co/Comfy-Org/BiRefNet/resolve/main/background_removal/birefnet.safetensors> | `ComfyUI_source\models\background_removal` |

Verify names and nonzero sizes:

```powershell
Get-ChildItem .\ComfyUI_source\models\diffusion_models, .\ComfyUI_source\models\text_encoders, .\ComfyUI_source\models\vae -File |
    Select-Object FullName, Length
Get-ChildItem .\ComfyUI_source\models\background_removal\birefnet.safetensors |
    Select-Object FullName, Length
```

Approximate sizes are 7.3 GB for the transformer, 6.3 GB for the W4A8 text encoder, 0.7 GB for the VAE, and 0.4 GB for BiRefNet. Do not substitute `qwen3vl_8b_int8_convrot.safetensors` for the W4A8 file in this 8 GB configuration.

BiRefNet is only loaded by `qwen21_background_removal_workflow.json`; it is not required for text-to-image, image modification, image combining, or mask-guided inpainting.

## 5. Workflow files and local inputs

The repository includes five importable workflow JSONs:

- `qwen21_text_to_image_workflow.json`: baseline text-to-image.
- `qwen21_image_modification_workflow.json`: edit `qwen21_edit_source.png` with text and an optional second reference.
- `qwen21_image_combine_workflow.json`: combine `qwen21_combine_base.png` and `qwen21_combine_subject.png`; prompts use `<image1>` and `<image2>`.
- `qwen21_inpainting_workflow.json`: edit `qwen21_inpaint_source.png` and composite only the white region of `qwen21_inpaint_mask.png` over the original.
- `qwen21_background_removal_workflow.json`: remove the background with BiRefNet and save an RGBA PNG.

Load a JSON into ComfyUI by opening it from the Workflows menu or dragging it onto the ComfyUI page. The sample input names are only defaults; replace the `LoadImage` or `LoadImageMask` node values with your own files under `ComfyUI_source\input`.

## 6. Launching ComfyUI

The project launcher is:

```text
run_comfyui_qwen_image.bat
```

Run it from PowerShell or double-click it:

```powershell
Set-Location E:\qwen_image_dev
.\run_comfyui_qwen_image.bat
```

The launcher uses this effective command line:

```text
--windows-standalone-build
--base-directory ComfyUI_source
--auto-launch
--enable-dynamic-vram
--async-offload 2
--reserve-vram 1.0
```

The small Python wrapper inside the batch file puts `ComfyUI_source` first on `sys.path`. This matters because the portable archive may contain an older bundled ComfyUI source tree; the launcher must use the separately cloned source checkout that contains the current Qwen Image 2.1 nodes.

### Initial flag decisions for an 8 GB RTX 4060

| Option | Decision | Reason |
| --- | --- | --- |
| `--enable-dynamic-vram` | Use | Main memory-management strategy for this machine |
| `--async-offload 2` | Use | Allows asynchronous CPU/RAM offload with two streams |
| `--reserve-vram 1.0` | Use | Leaves approximately 1 GB for Windows/desktop/GPU background use |
| `--lowvram` | Do not use initially | DynamicVRAM already manages placement; this can add overhead or interact poorly |
| `--highvram` | Do not use | Opposite of the desired streaming behavior |
| `--gpu-only` | Do not use | Attempts to keep models on the GPU and defeats RAM offload |
| `--disable-async-offload` | Do not use | Removes a useful performance feature |
| `--disable-smart-memory` | Do not use | Retain ComfyUI's normal memory management |
| `--vram-headroom` | Do not add initially | Start with the launcher's fixed 1 GB reserve; tune only if logs show a need |

Do not run a raw full-BF16, GPU-only Qwen Image setup on this GPU. The intended setup is quantized inference with model streaming.

## 7. First workflow and validation

1. Close `llama-server`, games, browsers using GPU acceleration, and any other local model server.
2. Run the `nvidia-smi` command above and confirm at least 6 GiB free, preferably 7 GiB.
3. Start `run_comfyui_qwen_image.bat` and leave its console window open.
4. Open <http://127.0.0.1:8188> if it does not open automatically.
5. Load `qwen21_text_to_image_workflow.json` from this repository, or use the native Qwen Image 2.1 text-to-image template from ComfyUI's Templates menu.
6. Confirm the workflow selects the three filenames listed in Section 4.
7. Confirm `EmptySD3LatentImage` or the equivalent size node is 1024x1024, the sampler is 25 steps, and batch size is 1.
8. Enter a short prompt such as `a cheerful cartoon frog sitting on a lily pad, bright colors, clean illustration` and queue one prompt.
9. Confirm an image appears in the UI and is written under `ComfyUI_source\output`.

Useful local checks while ComfyUI is running:

```powershell
Invoke-WebRequest http://127.0.0.1:8188/system_stats | Select-Object -ExpandProperty Content
nvidia-smi --query-gpu=name,memory.used,memory.free,utilization.gpu --format=csv
```

The expected result is that the nodes load, the first run takes longer while the large files are loaded/offloaded, and peak VRAM stays below the 8 GB limit. System RAM will be used heavily; that is expected for this configuration.

## 8. Performance expectations

This is runnable on an 8 GB RTX 4060 Laptop GPU, but it is not a fast, fully resident setup.

- Peak VRAM: expect roughly 5.5-7.5 GiB depending on ComfyUI/PyTorch version, background GPU usage, and memory fragmentation. Keep the 1 GiB reserve.
- System RAM: expect many gigabytes while the 7.3 GB transformer and 6.3 GB text encoder are active. 64 GB is a comfortable capacity; an SSD pagefile is still useful.
- Disk: use an SSD. Slow storage or an exhausted pagefile can turn offload into severe disk thrashing.
- 1024x1024 / 25 steps / batch 1: expect minutes rather than seconds. A practical first-run range is roughly 2-8 minutes, with the exact result depending strongly on laptop power mode, thermals, PyTorch build, and offload behavior.
- INT8 vs INT4: use the official INT8 ConvRot transformer plus W4A8 text encoder first. Move to a compatible INT4 variant only if the official workflow/model card supports it and INT8 cannot fit; lower precision can trade image quality and compatibility for memory savings.

## 9. Updating the setup

Update the project documentation/workflow normally:

```powershell
git pull --ff-only
```

Update the separate ComfyUI checkout and its embedded-Python dependencies:

```powershell
git -C .\ComfyUI_source pull --ff-only
$py = (Resolve-Path .\python_embeded\python.exe).Path
& $py -m pip install -r .\ComfyUI_source\requirements.txt
```

After a ComfyUI update, re-run the validation steps and confirm the Qwen nodes are still present. Do not run `pip` using a different system Python and expect the embedded runtime to use those packages.

## 10. Troubleshooting

### ComfyUI does not start or `main.py` is missing

Check the two paths expected by the launcher:

```powershell
Test-Path .\python_embeded\python.exe
Test-Path .\ComfyUI_source\main.py
```

If either is `False`, extract the portable archive or clone the ComfyUI source checkout again in the project root. The source must be `ComfyUI_source`, not a nested `ComfyUI_source\ComfyUI_source` directory.

### Qwen node is missing

Start through `run_comfyui_qwen_image.bat`, not an old portable launcher. The launcher intentionally selects `ComfyUI_source`. Update that checkout and its requirements, then restart ComfyUI. The native node to look for is the Qwen Image 2.1 text encoder node, not a custom-node replacement.

### Model file is missing

The model files belong under `ComfyUI_source\models`, not under the old portable source tree and not beside the launcher. Check exact spelling:

```powershell
Get-ChildItem .\ComfyUI_source\models\diffusion_models\qwen_image_2.1_int8_convrot.safetensors
Get-ChildItem .\ComfyUI_source\models\text_encoders\qwen3vl_8b_w4a8.safetensors
Get-ChildItem .\ComfyUI_source\models\vae\qwen_image_2.1_vae_bf16.safetensors
```

If a file is zero bytes or much smaller than the approximate sizes in Section 4, resume or restart its download.

### VRAM out of memory

First stop the current generation, close `llama-server` and other GPU users, and run:

```powershell
nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free --format=csv
```

If free VRAM is not close to 6-7 GiB, do not start the test yet. If it is free and the workflow still fails, temporarily test 768x768 or 896x896, keep batch size 1, and retain DynamicVRAM. Do not add `--gpu-only` or `--highvram`.

### CUDA or PyTorch mismatch

Use the embedded Python check in Section 3.3. If it reports CUDA unavailable, a different Python is being used, or the portable runtime is damaged, reinstall/extract a fresh official NVIDIA portable archive and run:

```powershell
$py = (Resolve-Path .\python_embeded\python.exe).Path
& $py -m pip install -r .\ComfyUI_source\requirements.txt
```

Do not install a random CUDA/PyTorch combination into the system Python. The NVIDIA driver must also be current enough for the portable build's CUDA/PyTorch version.

### Slow generation, paging, or disk thrash

Keep all model files and the Windows pagefile on an SSD, close unnecessary applications, use the laptop's performance power mode, and avoid running another large local model at the same time. A long first run is normal; repeated disk activity with little GPU utilization indicates RAM/pagefile pressure rather than a prompt problem.

### ComfyUI cannot see files after moving the project

The launcher passes `--base-directory ComfyUI_source`, so model discovery is relative to that source checkout. Keep `ComfyUI_source` and `python_embeded` beside the launcher, or update the launcher paths if deliberately relocating them.

## 11. Git and large-file policy

This repository does not use Git LFS. The `.gitignore` excludes:

- the portable runtime;
- the separate ComfyUI source checkout;
- all model binaries and generated images;
- logs, caches, databases, temporary downloads, and local state.

The tracked workflow `qwen21_text_to_image_workflow.json`, launcher, documentation, and Git metadata are the reproducible project layer. A fresh clone becomes runnable by following this document and downloading the official binaries/models into the documented directories.
