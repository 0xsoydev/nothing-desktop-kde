#!/usr/bin/env bash
# Installs and applies the whole Nothing desktop on Arch + KDE Plasma 6 (Wayland):
#   Nothing KDE theme (island, dock, widgets, Glassy), Spotlight (Alt+Space), power menu (Meta+Shift+P),
#   lock screen (Meta+L), SDDM login theme, and pacman hooks that keep the built parts working.
# Run from inside a Plasma session as your normal user. Safe to re-run.
set -euo pipefail
REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/nothing-desktop-kde"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
PACKAGES=(git python cmake gcc make qt6-tools qt6-declarative qt6-wayland qt6-5compat
          kpackage kwindowsystem kglobalaccel kirigami milou krunner layer-shell-qt
          plasma-desktop plasma-workspace kscreenlocker kvantum aurorae sddm
          plasma-nm plasma-pa bluez-qt powerdevil libksysguard)

say() { printf '\n==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# ---- preflight -----------------------------------------------------------
(( EUID != 0 )) || die "run as your normal user, not root (sudo is asked for when needed)"
command -v pacman >/dev/null || die "Arch Linux (pacman) is required"
[[ "$REPO" != *[[:space:]]* ]] || die "move the repo to a path without spaces (pacman hooks can't handle them)"
[[ "${XDG_SESSION_TYPE:-}" == wayland ]] || die "run this inside a Plasma Wayland session"
pgrep -x plasmashell >/dev/null || die "plasmashell is not running; log into Plasma first"
[[ "$(plasmashell --version | awk '{print $2}')" == 6.* ]] || die "Plasma 6 is required"

say "Asking for sudo (packages, login theme, pacman hooks)"
sudo -v
while sleep 50; do sudo -n true; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
SUDO_KEEPALIVE=$!
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT

say "Installing missing packages"
sudo pacman -S --needed "${PACKAGES[@]}"

# ---- snapshot (first install only, so uninstall goes back to the pre-Nothing desktop) ----
if [[ ! -d "$STATE/backup" ]]; then
  say "Snapshotting current KDE settings to $STATE/backup"
  mkdir -p "$STATE/backup"
  cd "$HOME"
  paths=()
  for p in .config/{kdeglobals,plasmarc,plasma-org.kde.plasma.desktop-appletsrc,plasmashellrc,kwinrc,kscreenlockerrc,ksplashrc,kcminputrc,kglobalshortcutsrc,breezerc,dolphinrc,kdedefaults,Kvantum,gtk-3.0,gtk-4.0,kitty,kwinrulesrc,plasmanotifyrc,knotifyrc,ksmserverrc,plasma-localerc,kded6rc,kiorc,krunnerrc,Trolltech.conf,xsettingsd,autostart,systemd/user} \
           .local/share/{plasma,color-schemes,aurorae,sounds,kwin}; do
    [[ -e "$p" ]] && paths+=("$p")
  done
  printf '%s\n' "${paths[@]}" > "$STATE/backup/paths.txt"
  tar czf "$STATE/backup/kde-config.tar.gz" "${paths[@]}"
  pacman -Qqe > "$STATE/backup/packages-before.txt"
  cd "$REPO"
else
  say "Keeping the existing pre-install snapshot in $STATE/backup"
fi

# ---- Nothing KDE: packages, island + dock layout, global theme ----------
say "Installing Nothing KDE (island, dock, widgets, Glassy)"
(cd "$REPO/vendor/Nothing-Kde-Theme" && ./install.sh --apply-layout)
for _ in $(seq 40); do qdbus6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 && break; sleep 0.5; done
sleep 2
plasma-apply-lookandfeel -a com.nothingplasma.dark

say "Removing non-Nothing panels, setting the dock to auto-hide"
qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
for (const p of panelIds.map(panelById)) {
  if (p.type !== "com.nothingplasma.panel") p.remove();
  else if (p.location === "bottom") p.hiding = "autohide";
}' >/dev/null
"$DATA/nothing-plasma/bin/nothing-control.sh" launcher-meta on

# ---- our parts ------------------------------------------------------------
say "Installing Spotlight + power menu"
"$REPO/spotlight-kde/install.sh"

say "Installing the lock screen"
"$REPO/nothing-lockscreen/install.sh"

say "Installing the SDDM login theme"
sudo rm -rf /usr/share/sddm/themes/nothing-glyph
sudo cp -r "$REPO/nothing-sddm" /usr/share/sddm/themes/nothing-glyph
sudo mkdir -p /etc/sddm.conf.d
printf '[Theme]\nCurrent=nothing-glyph\n' | sudo tee /etc/sddm.conf.d/zz-nothing-glyph.conf >/dev/null

say "Installing pacman hooks"
sudo mkdir -p /etc/pacman.d/hooks
for t in "$REPO"/hooks/*.hook.in; do
  name="$(basename "$t" .in)"
  sed -e "s|@USER@|$USER|g" -e "s|@REPO@|$REPO|g" "$t" | sudo tee "/etc/pacman.d/hooks/$name" >/dev/null
done

say "Reloading Plasma"
kbuildsycoca6 >/dev/null 2>&1 || true
systemctl --user restart plasma-plasmashell.service

cat <<EOF

Done. Log out and back in once so everything reloads.
  Alt+Space    Spotlight          Meta+Shift+P  power menu
  Meta         Nothing launcher   Meta+L        lock screen
Undo with: $REPO/uninstall.sh
EOF
