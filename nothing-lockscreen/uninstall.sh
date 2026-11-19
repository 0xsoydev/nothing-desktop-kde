#!/usr/bin/env bash
# Removes the Nothing lock screen overlay; Plasma's own lock screen is used again from the next lock.
set -uo pipefail
DST="$HOME/.local/share/plasma/shells/org.kde.plasma.desktop"
if [[ -e "$DST/.nothing-lockscreen" ]]; then
  rm -rf "$DST"
  rmdir "$HOME/.local/share/plasma/shells" 2>/dev/null
  echo "Nothing lock screen removed."
fi
exit 0
