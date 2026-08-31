# rice-config

Source-controlled configuration and custom helpers for a Hyprland desktop.
This repository stores configuration, themes, policy, and deployment logic;
the programs themselves are installed separately.

## Layout

- `config/hypr/` — Hyprland, idle, lock, and keybind configuration.
- `config/kitty/` — Kitty behavior, appearance, themes, and tracked default.
- `config/rofi/` — Rofi behavior, themes, application policy, and app-specific helpers.
- `config/rice-theme/` — desktop theme profiles and the tracked default profile.
- `config/swaync/` — notification/control-center layout, themes, and service policy.
- `config/thunar/` — Thunar preferences, thumbnail policy, custom actions, and MIME defaults.
- `config/waybar/` — Waybar layout, logical module groups, themes, and user service.
- `scripts/theme-selector/` — desktop and component theme commands.
- `scripts/` — other helpers deployed through `~/.local/bin/`.
- `setup.sh` — conservative, idempotent symlink deployment and validation.

The live component directories below `~/.config` are symlinks into the clone.
Managed commands and the two Rofi gateway desktop entries are individual
symlinks. From the clone root, run:

```bash
./setup.sh
```

Existing unrelated destinations are reported as conflicts and are not
overwritten. On Ubuntu/Debian, setup installs only missing required
file-manager packages; the remaining desktop software is installed separately.
Use `./setup.sh --skip-package-install` only when applying configuration without
root access; missing commands are still reported by validation.

## Themes

Available themes and each application's `default-theme` declaration are
tracked. Setup creates ignored, machine-local selectors together under
`config/rice-theme/selectors/`, initialized to those defaults, so later theme
changes leave Git clean.

```bash
rice-theme current
rice-theme list
rice-theme ghost-shell
rice-theme default

hyprland-theme list
swaync-theme list
kitty-theme list
kitty-theme ghost-shell
kitty-theme default

rofi-theme list
rofi-theme ghost-shell
rofi-theme default

waybar-theme list
waybar-theme ghost-shell
waybar-theme default
```

The `default` command activates the tracked default. To select Kitty's theme
named `default` instead, use `kitty-theme default.conf`.

The tracked `ghost-shell` desktop profile maps Hyprland, Waybar, SwayNC, Rofi,
and Kitty to their respective `ghost-shell` themes. `rice-theme` validates all
five mappings before applying a profile and reports component drift from the
selected profile in `rice-theme current`.

Ubuntu's SwayNC 0.12.4 is intentionally retained for the MPRIS, volume,
backlight, DND, and notification widgets. The Waybar clock opens the separate
`waycal` month popup, while the Control Center module opens SwayNC (right-click
toggles DND). This separation avoids replacing the distribution SwayNC build.
Waycal remains an external, user-installed program and is not part of
`rice-theme` because it currently has no supported theme/config interface.
The Waybar clock and `Super+D` share `waycal-toggle`; `Super+N` toggles SwayNC.
The Waybar power button and `Super+Escape` toggle the same Rofi power menu.
Waybar and SwayNC both follow the `pipewire-pulse` default sink. Waybar displays
nearest-integer percentages; SwayNC 0.12.4 exposes only its native continuous
slider (with no percentage label or configurable volume rounding), and its
generated slider-value tooltips are hidden by the SwayNC theme. The MPRIS
widget filters the redundant `playerctld` proxy. SwayNC's Spotify metadata rule
normalizes its per-app volume label and supplies the installed `spotify-client`
icon name.

## Rofi application policy

`config/rofi/apps/hidden/apps.list` omits applications from launchers.
`config/rofi/apps/system/apps.list` moves applications into the separate
System Applications gateway. Both are tracked preferences based on desktop-entry
IDs. Generated overrides remain in the user's XDG applications directory, and
recovery data for pre-existing user entries lives under
`${XDG_STATE_HOME:-~/.local/state}/rice-config/rofi/`.

Run either gateway directly with `rofi-apps hidden` or `rofi-apps system`.

## File manager

Thunar is the Ghost Shell file manager because it provides a lightweight GTK3
base with detailed and icon views, tabs, optional split view, native custom
actions, and GVfs integration. It uses the system Adwaita dark GTK and icon
foundation; there is no Thunar-specific CSS or copied icon theme. A tiny
`GhostShell` theme inherits Adwaita and overrides only the standard `go-home`
and `document-open-recent` icons with restrained `#e8e8e8`/`#728DBE` artwork.
Because these are standard icon names, the two overrides can also appear in
other GTK applications; every other icon continues through normal inheritance.
The native dark color preference and toolkit-provided blue accent are applied
where supported; the repository does not override toolkit colors to force an
exact RGB value.

`setup.sh` installs missing Thunar, Tumbler, archive, GVfs, MTP, UDisks, and
Kitty dependencies. It applies the declarations in
`config/thunar/xfconf.settings`, merges the native Desktop visibility setting,
links the narrow Tumbler policy, merges the managed Kitty action into the
user's existing `Thunar/uca.xml`, and applies MIME defaults one at a time. Existing unrelated
custom actions, MIME associations, and GTK bookmarks survive. Documents,
Downloads, and Pictures are the managed core bookmarks; Desktop, Music, and
Videos are omitted. The native Desktop shortcut is hidden through Thunar's
`hidden-bookmarks` preference without changing the XDG Desktop directory.
Other bookmarks and hidden shortcuts remain user-managed.

The default is a compact detailed list with Name, Size, Type, and Modified,
folders first, name-ascending sorting, hidden files off, breadcrumbs, and a
small native toolbar. Tabs and `F3` split view remain available but are not the
default layout. There is no preview pane. Tumbler creates local image and PDF
still thumbnails up to 100 MiB, including on locally mounted removable media;
network, video, audio, and arbitrary external thumbnailers are disabled.
Thumbnail cache and navigation/window history remain runtime state outside Git.

The native Thunar archive plugin uses File Roller with 7-Zip support for ZIP,
tar archives, 7z, and RAR extraction, and for ZIP or tar.gz creation. Its
**Extract Here** mode creates an archive-named destination folder, preventing
loose files from being sprayed into the current directory. If an archive already
contains the same top-level folder, File Roller may retain that extra nesting;
the repository accepts the native behavior instead of adding an extraction
wrapper.
Thunar 4.20 exposes **Extract Here**, **Extract To...**, and **Create Archive...**
at the top level; it cannot put extension actions under an `Archive` submenu
without replacing the native plugin with custom actions.

Thunar's resident daemon and `thunar-volman` automount removable storage without
opening a window or forcing busy unmounts. GVfs supplies Trash, SFTP, SMB, NAS,
and MTP browsing. No network location is configured to reconnect at login.
Device, network, eject, and error presentation remain native to Thunar and
GVfs/UDisks.

Thunar 4.20 owns the shortcuts model and exposes only Places, Devices, and
Network groups. Trash remains a fixed Places item and cannot be moved below
Network through a supported preference. User-added bookmarks likewise remain
inside Places; there is no native independent Bookmarks header. The repository
does not fake either layout with dummy entries or CSS.

Default handlers retain the installed Loupe image viewer, Papers PDF viewer,
GNOME Text Editor for `text/plain`, Visual Studio Code for distinct development
MIME types, mpv for audio/video, and Google Chrome for web URLs. File Roller is
the single archive handler. Linux MIME detection classifies both `.txt` and many
`.conf`/`.ini` files as `text/plain`, so those extensions cannot have different
defaults without a custom MIME database; **Open With** remains available for
choosing VS Code.

```text
Super+F       open Thunar at Home
Ctrl+H        toggle hidden files
Ctrl+L        edit/type the current path
Ctrl+W        close the current tab (or the window on its last tab)
F2            rename
F3            toggle split view
Delete        move to Trash
Shift+Delete  permanently delete with confirmation

Open Terminal Here
               open Kitty in the current folder, selected folder,
               or selected file's parent folder (one selection only)
```

Repository-managed state is limited to declared preferences, thumbnail policy,
core bookmarks, the two-icon inherited theme, the Kitty action, MIME defaults,
dependencies, and daemon startup. GTK/icon packages, thumbnail cache, recent files, mounts, remembered
network locations, extra bookmarks, and window geometry remain system- or
user-managed.

## Software installed separately

Command names describe capabilities; Linux distribution package names can
differ.

- Core desktop: Hyprland/`hyprctl`, Kitty, Rofi 2.x, Bash, standard GNU-style
  shell utilities, `jq`, and GIO/GLib.
- Session companions: Hypridle, Hyprlock, Waybar, Sway Notification Center,
  SwayOSD, and the Hyprland polkit agent with its matching QML style module.
- Configured features: `brightnessctl`, `playerctl` support through SwayOSD,
  JetBrains Mono, DejaVu Sans Mono, and an icon theme providing common symbolic
  icons. File-manager packages are the exception: setup installs their missing
  Ubuntu/Debian dependencies as documented above.
- Waybar controls: `waycal`, `wlctl`, NetworkManager's `nmtui`, `bluetui`,
  `wiremix`, WirePlumber's `pw-dump` and `wpctl`, Power Profiles Daemon, and
  the Rofi-based power menu. Install waycal separately from its official
  release; setup only reports when it is unavailable.
- Screenshots: Hyprshot, `grim`, `slurp`, `jq`, `wl-copy`, `notify-send`, and
  `xdg-user-dir`. `hyprpicker` is optional for Hyprshot's freeze mode.

Hyprshot is an external dependency and is not managed or modified by this
repository.

Hyprland imports the current Wayland session environment, clears any prior
start-limit failure, and restarts the Waybar, SwayNC, and polkit user services.
On compositor shutdown it stops those services so they cannot restart against
the departed Wayland display. Systemd remains the sole process owner. Recover
the panel and notification daemon manually with:

```bash
systemctl --user restart waybar.service
systemctl --user restart swaync.service
```

Other graphical companions continue to start directly through `exec-once`. On
Ubuntu, the polkit agent's `org.hyprland.style` dependency is provided by
`qml6-module-org-hyprland-style`.

## Validation

`setup.sh` checks links, important commands, and the Hyprland, Kitty, Rofi,
Thunar, Waybar, SwayNC, and desktop-entry configurations where their validators
are available. Useful manual checks include:

```bash
Hyprland --verify-config --config ~/.config/hypr/hyprland.conf
hyprctl configerrors
keybind-help --print
git diff --check
```

Keyboard layout, automatic monitor selection, touchpad behavior, battery idle
policy, and application classifications are intentionally current-machine
preferences rather than a multi-machine abstraction.
