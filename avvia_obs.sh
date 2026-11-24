#!/usr/bin/env bash
# Preview window only, for OBS "Window Capture (Xcomposite)" / screen capture.
exec "$(dirname "${BASH_SOURCE[0]}")/avvia_locale.sh" --no-virtual-camera --no-countdown "$@"
