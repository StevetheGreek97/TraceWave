#!/usr/bin/env bash
set -euo pipefail

VENV="${VENV:-.venv}"
PYTHON="${PYTHON:-python3}"
INSTALL_FULL=1
DOWNLOAD_WEIGHTS=1

SAM2_URL="https://huggingface.co/facebook/sam2-hiera-tiny/resolve/main/sam2_hiera_tiny.pt"
SAM2_WEIGHTS="src/sam2_configs/sam2_hiera_tiny.pt"

usage() {
  cat <<EOF
Usage: ./install.sh [options]

Options:
  --venv <path>     Virtual env directory (default: .venv)
  --python <path>   Python executable (default: python3)
  -h, --help        Show help

Environment:
  VENV, PYTHON can also be set via env vars.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --venv)
      VENV="$2"
      shift
      ;;
    --python)
      PYTHON="$2"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

if ! command -v "$PYTHON" >/dev/null 2>&1; then
  echo "Error: Python not found: $PYTHON"
  exit 1
fi

install_ffmpeg() {
  if command -v ffmpeg >/dev/null 2>&1 && command -v ffprobe >/dev/null 2>&1; then
    echo "FFmpeg and FFprobe already installed."
    return 0
  fi

  echo "FFmpeg/FFprobe not found. Installing..."

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y ffmpeg
    return 0
  fi

  if command -v brew >/dev/null 2>&1; then
    brew install ffmpeg
    return 0
  fi

  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y ffmpeg
    return 0
  fi

  if command -v yum >/dev/null 2>&1; then
    sudo yum install -y ffmpeg
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm ffmpeg
    return 0
  fi

  echo "Error: Unsupported package manager. Please install ffmpeg and ffprobe manually."
  echo "See: https://ffmpeg.org/download.html"
  exit 1
}

install_ffmpeg

if [[ ! -d "$VENV" ]]; then
  "$PYTHON" -m venv "$VENV"
fi

PIP="$VENV/bin/pip"
PY="$VENV/bin/python"

"$PIP" install --upgrade pip

if [[ "$INSTALL_FULL" -eq 1 ]]; then
  "$PIP" install -e ".[sam2,yaml]"
else
  "$PIP" install -e .
fi

if [[ "$DOWNLOAD_WEIGHTS" -eq 1 ]]; then
  mkdir -p "$(dirname "$SAM2_WEIGHTS")"
  if [[ -f "$SAM2_WEIGHTS" ]]; then
    echo "SAM2 weights already present at $SAM2_WEIGHTS"
  else
    echo "Downloading SAM2 weights to $SAM2_WEIGHTS"
    if command -v curl >/dev/null 2>&1; then
      curl -L -o "$SAM2_WEIGHTS" "$SAM2_URL"
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$SAM2_WEIGHTS" "$SAM2_URL"
    else
      echo "Error: curl or wget is required to download weights."
      exit 1
    fi
  fi
fi

cat <<EOF
Done.
Activate with: source "$VENV/bin/activate"
Run with: $PY -m src.tracewave
EOF
