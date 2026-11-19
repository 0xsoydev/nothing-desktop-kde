#!/usr/bin/env bash
# Rebuilds Spotlight against the current Qt/KDE libraries and restarts it. Run by the pacman hook as the user.
# The old binary is kept if the build fails.
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# Set explicitly: under pacman these may be missing or inherited from root.
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

cmake -S "$HERE/app" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1
cmake --build "$HERE/build" -j --clean-first >/dev/null
install -Dm755 "$HERE/build/spotlight-kde" "$HOME/.local/bin/spotlight-kde"
systemctl --user try-restart spotlight-kde.service 2>/dev/null || true
echo "spotlight-kde rebuilt"
