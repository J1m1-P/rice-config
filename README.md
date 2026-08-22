# rice-config

Source-controlled configuration and custom helpers for a Hyprland desktop.
This repository stores configuration, themes, policy, and deployment logic;
the programs themselves are installed separately.

## Layout

- `config/hypr/` — Hyprland, idle, lock, and keybind configuration.
- `config/kitty/` — Kitty behavior, appearance, themes, and tracked default.
- `config/rofi/` — Rofi behavior, themes, application policy, and app-specific helpers.
- `scripts/` — general helpers deployed through `~/.local/bin/`.
- `setup.sh` — conservative, idempotent symlink deployment and validation.

The live `~/.config/hypr`, `~/.config/kitty`, and `~/.config/rofi`
directories are symlinks into the clone. Managed commands and the two Rofi
gateway desktop entries are individual symlinks. From the clone root, run:

```bash
./setup.sh
```

Existing unrelated destinations are reported as conflicts and are not
overwritten. The script does not install packages.

## Themes

Available themes and each application's `default-theme` declaration are
tracked. Setup creates ignored, machine-local selectors initialized to those
defaults, so later theme changes leave Git clean.

```bash
kitty-theme list
kitty-theme black
kitty-theme default

rofi-theme list
rofi-theme ghost-v2
rofi-theme default
```

The `default` command activates the tracked default. To select Kitty's theme
named `default` instead, use `kitty-theme default.conf`.

## Rofi application policy

`config/rofi/apps/hidden/apps.list` omits applications from launchers.
`config/rofi/apps/system/apps.list` moves applications into the separate
System Applications gateway. Both are tracked preferences based on desktop-entry
IDs. Generated overrides remain in the user's XDG applications directory, and
recovery data for pre-existing user entries lives under
`${XDG_STATE_HOME:-~/.local/state}/rice-config/rofi/`.

Run either gateway directly with `rofi-apps hidden` or `rofi-apps system`.

## Software installed separately

Command names describe capabilities; Linux distribution package names can
differ.

- Core desktop: Hyprland/`hyprctl`, Kitty, Rofi 2.x, Bash, standard GNU-style
  shell utilities, `jq`, and GIO/GLib.
- Session companions: Hypridle, Hyprlock, Waybar, Sway Notification Center,
  SwayOSD, and the Hyprland polkit agent with its matching QML style module.
- Configured features: `brightnessctl`, `playerctl` support through SwayOSD,
  Thunar, JetBrains Mono, DejaVu Sans Mono, and an icon theme providing common
  symbolic icons.
- Screenshots: Hyprshot, `grim`, `slurp`, `jq`, `wl-copy`, `notify-send`, and
  `xdg-user-dir`. `hyprpicker` is optional for Hyprshot's freeze mode.

Hyprshot is an external dependency and is not managed or modified by this
repository.

Hyprland starts the graphical companions through `exec-once`; their optional
systemd user units should not also be enabled. On Ubuntu, the polkit agent's
`org.hyprland.style` dependency is provided by
`qml6-module-org-hyprland-style`.

## Validation

`setup.sh` checks links, important commands, and the Hyprland, Kitty, Rofi, and
desktop-entry configurations where their validators are available. Useful
manual checks include:

```bash
Hyprland --verify-config --config ~/.config/hypr/hyprland.conf
hyprctl configerrors
keybind-help --print
git diff --check
```

Keyboard layout, automatic monitor selection, touchpad behavior, battery idle
policy, and application classifications are intentionally current-machine
preferences rather than a multi-machine abstraction.
