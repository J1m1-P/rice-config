# Hyprland Desktop Guide

This configuration provides a keyboard-focused, tiled desktop with ten workspaces, animated windows, notifications, screenshots, media controls, automatic locking, and power-saving behavior.

`Super` means the Windows/logo key on most keyboards.

## Configuration files

`hyprland.conf` loads base behavior, keybindings, startup commands, window and
layer rules, then the active theme selector. Hypridle and Hyprlock keep their
separate daemon configurations.

## Everyday shortcuts

| Shortcut | Behavior |
| --- | --- |
| `Super` + `Q` | Open a Kitty terminal. |
| `Super` + `Tab` | Open or close the Rofi application launcher. |
| `Super` + `F` | Open the Thunar file manager. |
| `Super` + `C` | Close the active window. |
| `Super` + `L` | Lock the session. |
| `Super` + `M` | Exit Hyprland and end the desktop session immediately. |
| `Super` + `B` | Show or hide Waybar. |
| `Super` + `D` | Open or close the calendar. |
| `Super` + `F1` | Open the keybinding reference. |

## Moving around windows

Windows are arranged automatically in a tiled layout. New windows share the available screen instead of covering one another.

| Shortcut | Behavior |
| --- | --- |
| `Super` + arrow key | Move keyboard focus to the window in that direction. |
| Hold `Super` and drag with the left mouse button | Move a window. |
| Hold `Super` and drag with the right mouse button | Resize a window. |

Audio settings, Bluetooth settings, and network-connection settings open as floating windows rather than joining the tiled layout.

## Workspaces

Ten separate workspaces are available.

| Shortcut | Behavior |
| --- | --- |
| `Super` + `1` through `9` | Switch to workspace 1 through 9. |
| `Super` + `0` | Switch to workspace 10. |
| `Super` + `Shift` + `1` through `9` | Move the active window to workspace 1 through 9. |
| `Super` + `Shift` + `0` | Move the active window to workspace 10. |
| `Super` + mouse wheel | Move through workspaces in order. |

Moving a window to another workspace does not automatically follow it; use the corresponding workspace shortcut to view it.

## Notifications

Notifications appear through Sway Notification Center.

| Shortcut | Behavior |
| --- | --- |
| `Super` + `,` | Dismiss the newest notification. |
| `Super` + `Shift` + `,` | Dismiss all notifications. |
| `Super` + `N` | Open or close the notification panel. |
| `Super` + `Ctrl` + `,` | Open or close the notification panel. |
| `Super` + `Alt` + `,` | Turn Do Not Disturb on or off. |

## Screenshots

Screenshots are saved and copied to the clipboard, ready to paste into another application.

| Shortcut | Behavior |
| --- | --- |
| `Print Screen` | Select and capture a rectangular region. |
| `Alt` + `Print Screen` | Select and capture a window. |
| `Shift` + `Print Screen` | Select and capture an entire monitor. |

## Media, sound, and brightness

The keyboard's dedicated media keys control playback through compatible media applications:

- Previous track, next track, and play/pause are supported.
- Volume up and down can be held to repeat.
- Speaker mute and microphone mute are supported.
- Screen-brightness up and down can be held to repeat.
- Volume and brightness changes display an on-screen indicator.

## Automatic locking and power saving

When the computer remains unused:

1. After 5 minutes, screen brightness is reduced to 10%.
2. After 5 minutes 30 seconds, the session locks.
3. After 5 minutes 50 seconds, the displays turn off.
4. After 10 minutes, the computer suspends if it is running on battery power.

Moving the mouse or pressing a key restores the previous brightness and turns the displays back on. Applications such as video players may temporarily prevent these idle actions while they are actively playing media.

The computer also locks before it goes to sleep. After waking, the displays are turned back on.

## Lock screen

The lock screen shows:

- A blurred view of the current desktop.
- The current time.
- A centered password field.
- Visual feedback when the password is accepted or rejected.

The pointer is hidden while locked. Enter the account password to return to the desktop.

## Desktop appearance and input

- Connected monitors use their preferred resolution and are positioned automatically.
- The keyboard layout is US English.
- A mouse wheel uses conventional scrolling.
- A touchpad uses natural scrolling, where the content follows finger movement.
- Windows have small gaps, rounded corners, shadows, and a colored border around the active window.
- Opening, closing, focusing, and changing workspaces use smooth animations.

## Services available after sign-in

At the start of a new Hyprland session, the configuration launches:

- The Waybar desktop panel.
- Sway Notification Center.
- Automatic idle, lock, display, and suspend handling.
- The password prompt used when an application needs administrator permission.
- The SwayOSD server used by media, volume, and brightness keys.
