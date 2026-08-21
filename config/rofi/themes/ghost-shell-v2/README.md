# Ghost Shell v2 — Signal Grid

Edit `settings.rasi` for normal customization:

| Setting | Controls |
| --- | --- |
| `window-width` | Launcher width |
| `window-radius` | Outer corner roundness |
| `accent` | Ghost Shell blue (`#95aedb`) |
| `window-bg` | Panel darkness and Rofi transparency |
| `selected-bg` / `selected-border` | Selected-row fill and outline |
| `icon-size` | Application icon size |
| `theme-font` | Font family and size |
| spacing values | Window, input, and row compactness |

Rofi transparency is the alpha value in `window-bg`; it makes the panel
partially see-through. Hyprland blur is a compositor effect behind the Rofi
window. Existing Hyprland blur is already enabled, so no Hyprland change was
needed.

The result format uses native `drun-display-format`, showing the application
name and generic name when available. The prompt is native Rofi `>_` text.
