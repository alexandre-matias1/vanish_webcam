#!/usr/bin/env bash
# Requires the v4l2loopback virtual camera (see setup_virtual_camera.sh).
exec "$(dirname "${BASH_SOURCE[0]}")/avvia_locale.sh" --virtual-camera "$@"
