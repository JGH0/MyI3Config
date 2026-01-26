# MyI3Repo

This repository contains a very minimal and practical **i3 window manager** configuration.
It is designed to stay close to upstream i3 behavior while adding a few convenience features
for daily use.

The configuration focuses on:
- Predictable tiling behavior
- Keyboard-driven workflow
- Minimal visual noise
- Easy extensibility

No external theming frameworks or heavy abstractions are used.

---

## Features

- i3 (X11) based setup
- Mouse-follow focus (focus follows mouse hover)
- Simple, readable keybindings
- Keyboard layout switching (e.g. `ch_de` ↔ `us_workman`)
- Window moving and resizing via keyboard
- Minimal logout / power menu overlay
- Multi-monitor friendly (using `xrandr`)
- Compatible with standard i3 tools

---

## Required Packages

Install the following packages on Arch Linux:

### Core
- `i3-wm`
- `i3status` or `i3status-rust` (optional, if you use a status bar)
- `dmenu` or `rofi` (used for menus / overlays)
- `xorg-server`
- `xorg-xinit`

### Utilities
- `xrandr` (monitor configuration)
- `setxkbmap` (keyboard layout switching)
- `picom` (optional compositor)
- `alacritty` or `kitty` (terminal emulator)
- `feh` (optional, wallpaper)
- `playerctl` (optional, media keys)
- `brightnessctl` (optional, brightness keys)

### Lock / Power (optional)
- `i3lock` or `i3lock-color`
- `systemd` (already present on most systems)

Example install command:

```bash
sudo pacman -S i3-wm dmenu xrandr setxkbmap xorg-xinit
```

---

## Installation

1. Clone the repository:
```bash
git clone https://github.com/<your-username>/MyI3Repo.git
```

2. Create the i3 config directory:
```bash
mkdir -p ~/.config/i3
```

3. Copy the config:
```bash
cp MyI3Repo/config ~/.config/i3/config
```

4. Log into an i3 session.
If asked to generate a config, **choose NO**.

---

## Notes

- This config is intentionally minimal.
- You are expected to adjust keybindings, monitors, and applications to your system.
- All logic is kept inside the i3 config file for transparency.
- No scripts are required unless you explicitly add them.
