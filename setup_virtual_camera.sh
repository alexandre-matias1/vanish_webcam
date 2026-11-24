#!/usr/bin/env bash
# Install and load v4l2loopback so VanishCam can publish a virtual webcam
# on Linux (Ubuntu and Omarchy/Arch). Run once; uses sudo.
set -euo pipefail

VIDEO_NR="${VIDEO_NR:-10}"
LABEL="${LABEL:-VanishCam}"
OPTIONS="devices=1 video_nr=$VIDEO_NR card_label=$LABEL exclusive_caps=1"

if ! modinfo v4l2loopback >/dev/null 2>&1; then
  echo "[VanishCam] Instalando o v4l2loopback..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y v4l2loopback-dkms "linux-headers-$(uname -r)"
  elif command -v pacman >/dev/null 2>&1; then
    # Headers matching the running kernel (linux, linux-lts, linux-omarchy, ...).
    headers=""
    for kernel in $(pacman -Qq | grep -E '^linux(-[a-z0-9]+)?$' || true); do
      if pacman -Si "$kernel-headers" >/dev/null 2>&1 || pacman -Qi "$kernel-headers" >/dev/null 2>&1; then
        headers="$headers $kernel-headers"
      fi
    done
    # shellcheck disable=SC2086
    sudo pacman -S --needed v4l2loopback-dkms $headers
  else
    echo "Distribuição não reconhecida: instale o v4l2loopback manualmente." >&2
    exit 1
  fi
fi

if lsmod | grep -q '^v4l2loopback'; then
  echo "[VanishCam] O v4l2loopback já está carregado."
else
  # shellcheck disable=SC2086
  sudo modprobe v4l2loopback $OPTIONS
fi

read -r -p "Carregar a webcam virtual automaticamente a cada inicialização? [s/N] " answer
if [[ "${answer,,}" == s* || "${answer,,}" == y* ]]; then
  echo v4l2loopback | sudo tee /etc/modules-load.d/vanishcam-v4l2loopback.conf >/dev/null
  echo "options v4l2loopback $OPTIONS" | sudo tee /etc/modprobe.d/vanishcam-v4l2loopback.conf >/dev/null
  echo "[VanishCam] Configurado em /etc/modules-load.d e /etc/modprobe.d."
fi

echo "[VanishCam] Webcam virtual pronta: /dev/video$VIDEO_NR ($LABEL)."
echo "[VanishCam] Rode ./avvia_virtual.sh e escolha '$LABEL' no app de videochamada."
