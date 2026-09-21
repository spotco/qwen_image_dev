@echo off
setlocal

set "COMFY_ROOT=%~dp0ComfyUI_source"
set "COMFY_PYTHON=%~dp0python_embeded\python.exe"

if not exist "%COMFY_PYTHON%" (
    echo ComfyUI portable Python was not found:
    echo %COMFY_PYTHON%
    pause
    exit /b 1
)

if not exist "%COMFY_ROOT%\main.py" (
    echo ComfyUI main.py was not found:
    echo %COMFY_ROOT%\main.py
    pause
    exit /b 1
)

cd /d "%COMFY_ROOT%"

echo Starting ComfyUI for Qwen-Image-2.1...
echo DynamicVRAM: enabled
echo Async offload: 2 streams
echo Reserved VRAM: 1.0 GB
echo.

"%COMFY_PYTHON%" -s -c "import runpy,sys; sys.path.insert(0, r'%COMFY_ROOT%'); runpy.run_path(r'%COMFY_ROOT%\main.py', run_name='__main__')" ^
  --windows-standalone-build ^
  --base-directory "%COMFY_ROOT%" ^
  --auto-launch ^
  --enable-dynamic-vram ^
  --async-offload 2 ^
  --reserve-vram 1.0

echo.
echo ComfyUI has stopped.
pause

endlocal
