#!/usr/bin/env bash
# Removes the Spotlight launcher and gives Alt+Space back to KRunner.
set -uo pipefail
KGA=(busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel)

systemctl --user disable --now spotlight-kde.service 2>/dev/null
rm -f "$HOME/.config/systemd/user/spotlight-kde.service" "$HOME/.local/bin/spotlight-kde"
systemctl --user daemon-reload
"${KGA[@]}" unregister ss spotlight-kde toggle >/dev/null 2>&1
"${KGA[@]}" unregister ss spotlight-kde power >/dev/null 2>&1
"${KGA[@]}" setForeignShortcut asai 4 org_kde_powerdevil PowerOff 'Power Management' 'Power Off' 2 301989968 16777399 >/dev/null
rm -rf "$HOME/.local/share/fonts/nothing" && fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1
"${KGA[@]}" setForeignShortcut asai 4 org.kde.krunner.desktop _launch KRunner KRunner 3 150994993 16777362 134217760 >/dev/null
echo "Spotlight removed; Alt+Space opens KRunner again."
