#!/usr/bin/env bash
# Virtual microphone "VanishCam Mic" (PipeWire/PulseAudio, no sudo):
#   your chosen microphone + VanishCam sound effects -> "VanishCam Mic".
# Select "VanishCam Mic" as the microphone in Meet/Discord/etc.
#
# Usage:
#   ./setup_virtual_mic.sh            choose the microphone from a list
#   ./setup_virtual_mic.sh 2          use microphone number 2 of the list
#   ./setup_virtual_mic.sh status     show what is active
#   ./setup_virtual_mic.sh remove     remove the virtual microphone
set -euo pipefail

FX_SINK="vanishcam_fx"        # VanishCam plays its sounds here (see vanish_sound.py).
MIC_SOURCE="vanishcam_mic"    # What the call app records.
STATE="${XDG_RUNTIME_DIR:-/tmp}/vanishcam-virtual-mic.modules"

command -v pactl >/dev/null 2>&1 || {
  echo "pactl não encontrado. Instale: Ubuntu 'sudo apt install pulseaudio-utils'," \
       "Omarchy/Arch 'sudo pacman -S libpulse'." >&2
  exit 1
}

remove() {
  if [ -f "$STATE" ]; then
    # Unload in reverse order: virtual mic, loopback, then the sink.
    tac "$STATE" | while read -r module; do
      pactl unload-module "$module" 2>/dev/null || true
    done
    rm -f "$STATE"
  fi
  # Also clean modules left by an older run whose state file was lost.
  pactl list short modules | awk -v sink="$FX_SINK" -v mic="$MIC_SOURCE" \
    '$0 ~ "sink_name=" sink || $0 ~ "source_name=" mic || $0 ~ "sink=" sink {print $1}' |
    sort -rn | while read -r module; do pactl unload-module "$module" 2>/dev/null || true; done
}

status() {
  if pactl list short sources | awk '{print $2}' | grep -qx "$MIC_SOURCE"; then
    echo "[VanishCam] Microfone virtual ativo: 'VanishCam Mic'."
    pactl list short modules | grep -E "module-loopback.*sink=$FX_SINK" |
      sed -E 's/.*source=([^ ]+).*/[VanishCam] Microfone real usado: \1/'
  else
    echo "[VanishCam] Microfone virtual não está ativo."
  fi
}

case "${1:-}" in
  remove) remove; echo "[VanishCam] Microfone virtual removido."; exit 0 ;;
  status) status; exit 0 ;;
esac

# Real microphones: every source except monitors and our own virtual mic.
mapfile -t names < <(pactl list short sources | awk '{print $2}' |
                     grep -v '\.monitor$' | grep -vx "$MIC_SOURCE" || true)
if [ "${#names[@]}" -eq 0 ]; then
  echo "Nenhum microfone encontrado." >&2
  exit 1
fi

describe() {
  pactl list sources | awk -v name="$1" '
    $1 == "Name:" { found = ($2 == name) }
    found && $1 == "Description:" { sub(/^[ \t]*Description: /, ""); print; exit }'
}

default_source="$(pactl get-default-source 2>/dev/null || true)"
echo "Microfones disponíveis:"
for i in "${!names[@]}"; do
  mark=""; [ "${names[$i]}" = "$default_source" ] && mark="  (padrão)"
  printf "  %d) %s%s\n" "$((i + 1))" "$(describe "${names[$i]}")" "$mark"
done

choice="${1:-}"
if [ -z "$choice" ]; then
  read -r -p "Qual microfone usar? [1-${#names[@]}] " choice
fi
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#names[@]}" ]; then
  echo "Escolha inválida: $choice" >&2
  exit 1
fi
mic="${names[$((choice - 1))]}"

remove  # Re-running replaces the previous setup (e.g. to switch microphone).
{
  pactl load-module module-null-sink sink_name="$FX_SINK" \
    sink_properties=device.description=VanishCam-Mix
  pactl load-module module-loopback source="$mic" sink="$FX_SINK" \
    latency_msec=20 source_dont_move=true sink_dont_move=true
  pactl load-module module-remap-source master="$FX_SINK.monitor" \
    source_name="$MIC_SOURCE" source_properties=device.description=VanishCam-Mic
} > "$STATE"

echo "[VanishCam] Microfone virtual pronto: 'VanishCam Mic' = $(describe "$mic") + efeitos."
echo "[VanishCam] Na chamada, escolha 'VanishCam Mic' como microfone."
echo "[VanishCam] Para trocar o microfone, rode de novo. Para remover: ./setup_virtual_mic.sh remove"
echo "[VanishCam] O PipeWire apaga o microfone virtual ao reiniciar o PC; rode este script de novo."
