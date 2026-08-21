# Rofi application classification

`hidden/apps.list` and `system/apps.list` are the human-maintained classification
lists. Desktop entry IDs are used so display-name changes do not silently target
the wrong application.

`NORMAL` is the default: entries not listed in either file remain ordinary Rofi
applications. `UNSURE` entries are intentionally left out of both lists until
there is a reason to move them.

The lists do not modify package-owned files. Effective hides are represented by
same-ID user overrides in `~/.local/share/applications/`.

After editing either list manually, apply it with:

```bash
~/.config/rofi/scripts/hidden-apps.sh sync
~/.config/rofi/scripts/system-apps.sh sync
```

The Hidden Applications and System Applications menus update their respective
list and matching user overrides automatically. SYSTEM applications are hidden
from the normal `drun` results but remain launchable from the System Applications
menu.

Runtime backup/restore state lives under `apps/.hidden-apps/` and
`apps/.system-apps/`. The two gateway desktop entries use an invisible U+2063
sort prefix so they remain at the bottom of Rofi's otherwise alphabetical list.
