# nothing-desktop-kde

My NothingOS-style KDE Plasma 6 desktop, in one repo. Private: it ships Nothing's Ndot font and
unlicensed code from duckpah/Nothing-SDDM, which are fine for personal use but not for publishing.

## Restore on a fresh machine

Requirements: Arch Linux, KDE Plasma 6, logged into a Plasma **Wayland** session.

```sh
git clone <this repo> ~/Projects/nothing-desktop-kde
cd ~/Projects/nothing-desktop-kde
./install.sh
```

Log out and back in once afterwards. Keep the repo where you cloned it: the pacman hooks run scripts
from it. The path must not contain spaces.

## What it installs

| Part | Where it comes from | Shortcut |
|---|---|---|
| Nothing KDE v1.0.1: island, auto-hiding dock, 19 widgets, Glassy style, dark global theme | `vendor/Nothing-Kde-Theme` ([Contraill](https://github.com/Contraill/Nothing-Kde-Theme), GPL-3.0, commit `156f19a`) | Meta: Nothing launcher |
| Spotlight launcher (glass, KRunner's search engine) | `spotlight-kde/` (based on [Fenwyre](https://github.com/ankurpandeyvns/fenwyre), MIT) | Alt+Space (KRunner stays on Alt+F2) |
| Power menu | `spotlight-kde/app/PowerMenu.qml` (from [uzayr-iqbal-hamid/nothing-os-dots-hyprland](https://github.com/uzayr-iqbal-hamid/nothing-os-dots-hyprland), MIT) | Meta+Shift+P |
| Lock screen | `nothing-lockscreen/`: overlay of Plasma's shell package, only `contents/lockscreen` replaced | Meta+L |
| SDDM login theme `nothing-glyph` | `nothing-sddm/` ([glyph-sddm](https://github.com/xCaptaiN09/glyph-sddm), MIT, with a card after [duckpah/Nothing-SDDM](https://github.com/duckpah/Nothing-SDDM)) | — |
| Fonts Ndot 57, Space Mono | `nothing-sddm/assets/fonts` → `~/.local/share/fonts/nothing` | — |
| pacman hooks | `hooks/*.hook.in` → `/etc/pacman.d/hooks/` | rebuild Spotlight after Qt/KDE updates, relink the lock screen after Plasma updates |

`install.sh` also removes any panel that isn't a Nothing panel (so Meta reaches the Nothing launcher) and
sets the dock to auto-hide. Re-running it is safe.

## Undo

```sh
./uninstall.sh            # asks first; --yes to skip, --snapshot DIR for another snapshot
```

The first `install.sh` run snapshots your KDE settings to `~/.local/state/nothing-desktop-kde/backup`;
`uninstall.sh` removes everything above (including the sudo parts) and restores that snapshot.
Packages are never removed; it prints the ones added since the snapshot.

## If something breaks

- Spotlight or the power menu stop after an update: `./spotlight-kde/rebuild.sh`
- Login screen broken: Ctrl+Alt+F3, log in, `sudo rm /etc/sddm.conf.d/zz-nothing-glyph.conf`
- Lock screen broken: Plasma falls back to its built-in locker; from a console `loginctl unlock-session`,
  then `./nothing-lockscreen/uninstall.sh`
