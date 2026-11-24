#!/usr/bin/env bash
# Linux launcher (Ubuntu, Omarchy/Arch): equivalent of AVVIA_LOCALE.bat.
set -euo pipefail

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$APP_DIR/.venv-local"
VENV_PY="$VENV_DIR/bin/python"

fail() {
  echo
  echo "Não foi possível abrir o Vanish Lab: $1" >&2
  exit 1
}

distro_hint() {
  # $1 = apt packages, $2 = pacman packages
  if command -v apt-get >/dev/null 2>&1; then
    echo "  sudo apt install $1"
  elif command -v pacman >/dev/null 2>&1; then
    echo "  sudo pacman -S --needed $2"
  fi
}

if [ ! -x "$VENV_PY" ]; then
  PYTHON="${PYTHON:-python3}"
  command -v "$PYTHON" >/dev/null 2>&1 || {
    distro_hint "python3 python3-venv" "python"
    fail "Python 3 não encontrado."
  }
  echo "[Vanish Lab] Criando o ambiente Python local..."
  if ! "$PYTHON" -m venv "$VENV_DIR"; then
    rm -rf "$VENV_DIR"
    distro_hint "python3-venv" "python"
    fail "o módulo venv do Python não está disponível."
  fi
fi

# Also reinstall if an older venv still has MediaPipe 1.x (killed on Linux)
# or a pygame built from source without its mixer (Python 3.14+).
if ! "$VENV_PY" -c "import cv2, mediapipe, numpy, pyvirtualcam, pygame.mixer, PIL; assert mediapipe.__version__.startswith('0.10.')" >/dev/null 2>&1; then
  echo "[Vanish Lab] Instalando os componentes necessários. A internet só é necessária desta vez..."
  "$VENV_PY" -m pip install --upgrade pip || fail "falha ao atualizar o pip."
  if ! "$VENV_PY" -c "import pygame.mixer" >/dev/null 2>&1; then
    "$VENV_PY" -m pip uninstall -y pygame pygame-ce >/dev/null 2>&1 || true
  fi
  "$VENV_PY" -m pip install -r "$APP_DIR/requirements.txt" || fail "falha ao instalar as dependências."
fi

if [ -z "${DISPLAY:-}" ] && [ -n "${WAYLAND_DISPLAY:-}" ]; then
  echo "[Vanish Lab] Atenção: o XWayland não parece estar ativo (DISPLAY vazio)." >&2
  echo "[Vanish Lab] A janela do OpenCV precisa do XWayland." >&2
  distro_hint "xwayland" "xorg-xwayland"
fi

echo "[Vanish Lab] Abrindo a webcam..."
exec "$VENV_PY" "$APP_DIR/vanish_cam.py" "$@"
