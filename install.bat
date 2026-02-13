@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "VENV=%VENV%"
if "%VENV%"=="" set "VENV=.venv"

set "PYTHON=%PYTHON%"

if "%PYTHON%"=="" (
  where py >nul 2>nul && set "PYTHON=py -3"
)
if "%PYTHON%"=="" (
  where python >nul 2>nul && set "PYTHON=python"
)
if "%PYTHON%"=="" (
  where python3 >nul 2>nul && set "PYTHON=python3"
)

if "%PYTHON%"=="" (
  echo Error: Python not found. Install Python 3.9+ and ensure it is on PATH.
  exit /b 1
)

if not exist "%VENV%\" (
  %PYTHON% -m venv "%VENV%"
  if errorlevel 1 exit /b 1
)

set "PY=%VENV%\Scripts\python.exe"
set "PIP=%VENV%\Scripts\pip.exe"

if not exist "%PY%" (
  echo Error: Python not found at %PY%
  echo Tip: delete "%VENV%" and re-run this script.
  exit /b 1
)

"%PIP%" install --upgrade pip
if errorlevel 1 exit /b 1

"%PIP%" install -e ".[sam2,yaml]"
if errorlevel 1 exit /b 1

set "SAM2_URL=https://huggingface.co/facebook/sam2-hiera-tiny/resolve/main/sam2_hiera_tiny.pt"
set "SAM2_WEIGHTS=src\sam2_configs\sam2_hiera_tiny.pt"

if not exist "%SAM2_WEIGHTS%" (
  powershell -NoProfile -Command "$u='%SAM2_URL%'; $o='%SAM2_WEIGHTS%'; New-Item -ItemType Directory -Force -Path (Split-Path $o) | Out-Null; Invoke-WebRequest -Uri $u -OutFile $o"
  if errorlevel 1 (
    if exist "%SAM2_WEIGHTS%" (
      rem ok
    ) else (
      echo Error: Failed to download SAM2 weights.
      exit /b 1
    )
  )
)

echo Done.
echo Activate with: %VENV%\Scripts\activate.bat
echo Run with: %VENV%\Scripts\python.exe -m src.tracewave
