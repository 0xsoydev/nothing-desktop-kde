#!/usr/bin/env bash
# Installs the Nothing lock screen as a user overlay of Plasma's desktop shell package.
# kscreenlocker takes its lock screen from the shell package (plasmashellrc ShellPackage), so the overlay
# links every entry back to the system package except contents/lockscreen, which is ours.
# Re-run after plasma-workspace updates (the pacman hook does this) so new system files get linked.
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SYS=/usr/share/plasma/shells/org.kde.plasma.desktop
DST="$HOME/.local/share/plasma/shells/org.kde.plasma.desktop"
MARK=.nothing-lockscreen

[[ -d "$SYS/contents/lockscreen" ]] || { echo "No system shell package at $SYS" >&2; exit 1; }
if [[ -e "$DST" && ! -e "$DST/$MARK" ]]; then
  echo "$DST exists and was not made by this script; leaving it alone." >&2
  exit 1
fi

mkdir -p "$(dirname -- "$DST")"
stage="$(mktemp -d "${DST}.stage-XXXXXX")"
trap 'rm -rf "$stage"' EXIT
mkdir -p "$stage/contents/lockscreen"
touch "$stage/$MARK"
for f in "$SYS"/*; do [[ "${f##*/}" == contents ]] || ln -s "$f" "$stage/"; done
for f in "$SYS"/contents/*; do [[ "${f##*/}" == lockscreen ]] || ln -s "$f" "$stage/contents/"; done
# Keep System Settings > Screen Locking working.
for f in config.qml config.xml; do [[ -e "$SYS/contents/lockscreen/$f" ]] && ln -s "$SYS/contents/lockscreen/$f" "$stage/contents/lockscreen/"; done
cp -r "$HERE/lockscreen/." "$stage/contents/lockscreen/"
# Shared with the login theme: the card components, fonts and background.
SDDM="$HERE/../nothing-sddm"
cp "$SDDM"/components/{Ring,Avatar,Lb}.qml "$stage/contents/lockscreen/"
mkdir -p "$stage/contents/lockscreen/assets/images"
cp -r "$SDDM/assets/fonts" "$stage/contents/lockscreen/assets/"
cp "$SDDM/assets/images/background.jpg" "$stage/contents/lockscreen/assets/images/"
sed -i "s/@HOSTNAME@/$(uname -n)/" "$stage/contents/lockscreen/Clock.qml"

rm -rf "$DST"
mv "$stage" "$DST"
trap - EXIT
echo "Nothing lock screen installed at $DST"
