# Rofi theme template

Copy this directory:

```bash
cp -r ~/.config/rofi/themes/_template ~/.config/rofi/themes/my-new-theme
```

Edit `themes/my-new-theme/settings.rasi` and `themes/my-new-theme/theme.rasi`.
Activate it with:

```bash
rofi-theme my-new-theme
```

Keep reusable values in `settings.rasi` and layout/widget rules in
`theme.rasi`. Shared launcher behavior is in `config.rasi`.
