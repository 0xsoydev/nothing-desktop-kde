#!/usr/bin/env bash
# Removes everything install.sh added and restores the KDE settings snapshot it took before the first install.
# Usage: ./uninstall.sh [--yes] [--snapshot DIR]
set -uo pipefail
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nothing-desktop-kde"
B="$STATE/backup"
YES=0
while (( $# )); do
  case "$1" in
    --yes) YES=1 ;;
    --snapshot) B="${2:?--snapshot needs a directory}"; shift ;;
    *) echo "usage: $0 [--yes] [--snapshot DIR]" >&2; exit 2 ;;
  esac
  shift
done
failed=()

step() {
  local name="$1"; shift
  printf '==> %s\n' "$name"
  "$@" || { failed+=("$name"); printf '    (failed, continuing)\n' >&2; }
}

[[ -f "$B/kde-config.tar.gz" && -f "$B/paths.txt" ]] || { echo "No snapshot in $B" >&2; exit 1; }

if (( ! YES )); then
  cat <<EOF
This removes Nothing KDE, Spotlight, the power menu, the lock screen, the login theme and the pacman
hooks, and restores your KDE settings (theme, colours, icons, panels, KWin, shortcuts) from:
  $B
EOF
  read -r -p "Continue? [y/N] " ans
  [[ "$ans" == [yY]* ]] || { echo "Aborted."; exit 0; }
fi
sudo -v || exit 1

uninstall_nothing() {
  (cd "$REPO/vendor/Nothing-Kde-Theme" && ./uninstall.sh)
}

remove_leftovers() {
  rm -rf "$HOME/.local/share/kwin/decorations/org.glassy.decoration" \
         "$HOME/.config/nothing-kde" \
         "$HOME/.local/share/nothing-plasma" \
         "$HOME/.local/share/color-schemes/NothingPlasmaDark.colors" \
         "$HOME/.local/share/color-schemes/NothingPlasmaLight.colors"
  rmdir -p "$HOME/.local/share/kwin/decorations" 2>/dev/null || true
}

remove_system_parts() {
  sudo rm -rf /etc/sddm.conf.d/zz-nothing-glyph.conf /usr/share/sddm/themes/nothing-glyph \
              /etc/pacman.d/hooks/spotlight-kde-rebuild.hook /etc/pacman.d/hooks/nothing-lockscreen.hook
}

restore_snapshot() {
  systemctl --user stop plasma-plasmashell.service || true
  local p
  while IFS= read -r p; do
    [[ -n "$p" && "$p" != /* && "$p" != *..* ]] && rm -rf -- "${HOME:?}/$p"
  done < "$B/paths.txt"
  tar xzf "$B/kde-config.tar.gz" -C "$HOME"
}

# kglobalaccel lives in KWin and keeps shortcuts in memory, so set them live.
reset_shortcuts() {
  local acc=(busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcut asai 4)
  # KRunner: Alt+F2, Search, Alt+Space
  "${acc[@]}" org.kde.krunner.desktop _launch KRunner KRunner 3 150994993 16777362 134217760 >/dev/null
  # Application launcher: Meta, Alt+F1
  "${acc[@]}" plasmashell 'activate application launcher' plasmashell 'Activate Application Launcher' 2 16777250 150994992 >/dev/null
}

reload_desktop() {
  kbuildsycoca6 >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  systemctl --user start plasma-plasmashell.service
}

step "Remove Spotlight + power menu" "$REPO/spotlight-kde/uninstall.sh"
step "Remove Nothing lock screen" "$REPO/nothing-lockscreen/uninstall.sh"
step "Run Nothing KDE uninstaller" uninstall_nothing
step "Remove leftover Nothing/Glassy files" remove_leftovers
step "Remove login theme and pacman hooks" remove_system_parts
step "Restore KDE settings snapshot" restore_snapshot
step "Reset global shortcuts" reset_shortcuts
step "Reload KWin and Plasma" reload_desktop

echo
added="$(comm -13 <(sort "$B/packages-before.txt") <(pacman -Qqe | sort) 2>/dev/null)"
if [[ -n "$added" ]]; then
  echo "Packages installed since the snapshot (remove if you want):"
  echo "  sudo pacman -Rns $(echo $added)"
fi
if (( ${#failed[@]} )); then
  echo "Finished with problems in: ${failed[*]}"
else
  # Retire the snapshot so a later install takes a fresh one.
  [[ "$B" == "$STATE/backup" ]] && mv "$B" "$STATE/backup.restored-$(date +%Y%m%d-%H%M%S)"
  echo "Uninstall complete."
fi
echo "Log out and back in once so every component reloads."
