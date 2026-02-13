@echo off
setlocal EnableExtensions

set "VENV=%VENV%"
if "%VENV%"=="" set "VENV=.venv"

set "PY=%VENV%\Scripts\python.exe"

if not exist "%PY%" (
  echo Error: Python not found at %PY%
  echo Tip: run install.bat first.
  exit /b 1
)

"%PY%" -m src.tracewave
