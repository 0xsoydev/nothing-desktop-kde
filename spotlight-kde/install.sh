#!/usr/bin/env bash
# Builds and installs Spotlight (Alt+Space) and the Nothing power menu (Meta+Shift+P) as a user service,
# plus the Ndot 57 / Space Mono fonts the power menu uses.
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FONTS="$HERE/../nothing-sddm/assets/fonts"
BIN="$HOME/.local/bin/spotlight-kde"
UNIT="$HOME/.config/systemd/user/spotlight-kde.service"
KGA=(busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel)
# Shortcut changes are best effort: a component KDE has not registered yet has nothing to free.
kga() { "${KGA[@]}" "$@" >/dev/null 2>&1 || echo "    (shortcut not changed: $3 $4)" >&2; }

install -Dm644 -t "$HOME/.local/share/fonts/nothing" "$FONTS/Ndot-57-Aligned.ttf" "$FONTS/SpaceMono-Regular.ttf"
fc-cache -f "$HOME/.local/share/fonts" >/dev/null

cmake -S "$HERE/app" -B "$HERE/build" -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1
cmake --build "$HERE/build" -j >/dev/null
systemctl --user stop spotlight-kde.service 2>/dev/null || true
install -Dm755 "$HERE/build/spotlight-kde" "$BIN"
install -Dm644 "$HERE/spotlight-kde.service" "$UNIT"

# KRunner keeps Alt+F2 and the Search key; Alt+Space goes to Spotlight.
kga setForeignShortcut asai 4 org.kde.krunner.desktop _launch KRunner KRunner 2 150994993 16777362
# PowerDevil keeps the Power Off key; Meta+Shift+P goes to the Nothing power menu.
kga setForeignShortcut asai 4 org_kde_powerdevil PowerOff 'Power Management' 'Power Off' 1 16777399

systemctl --user daemon-reload
systemctl --user enable --now spotlight-kde.service
sleep 1
kga setForeignShortcut asai 4 spotlight-kde toggle Spotlight 'Toggle Spotlight' 1 134217760
kga setForeignShortcut asai 4 spotlight-kde power Spotlight 'Power Menu' 1 301989968
echo "Spotlight running as spotlight-kde.service on Alt+Space, power menu on Meta+Shift+P. KRunner: Alt+F2."
