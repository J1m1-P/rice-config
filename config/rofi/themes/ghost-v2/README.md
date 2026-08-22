# Ghost v2 — Signal Grid

Edit `settings.rasi` for normal customization:

| Setting | Controls |
| --- | --- |
| `window-width` | Launcher width |
| `window-radius` | Outer corner roundness |
| `accent` | Accent blue (`#95aedb`) |
| `window-bg` | Panel darkness and Rofi transparency |
| `selected-bg` / `selected-border` | Selected-row fill and outline |
| `icon-size` | Application icon size |
| `theme-font` | Font family and size |
| spacing values | Window, input, and row compactness |

The alpha value in `window-bg` controls panel transparency. Hyprland provides
the compositor blur behind the Rofi window.

The result format uses native `drun-display-format`, showing the application
name and generic name when available. The prompt is native Rofi `>_` text.
