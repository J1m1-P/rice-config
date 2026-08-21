# rice-config

Source-controlled Linux desktop configuration for Hyprland, Kitty, and Rofi.

## Layout

- `config/hypr/` — Hyprland, idle, lock, and keybind configuration.
- `config/kitty/` — Kitty configuration and themes.
- `config/rofi/` — Rofi configuration, application lists, scripts, and themes.
- `scripts/` — standalone helpers linked from `~/.local/bin/` or used by the configs.

The live `~/.config/hypr`, `~/.config/kitty`, and `~/.config/rofi` directories
are symlinks to the corresponding directories here. Managed executables in
`~/.local/bin/` are individual symlinks into `scripts/`.
