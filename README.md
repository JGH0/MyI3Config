# MyI3Repo

This repository contains a very minimal and practical **i3 window manager** configuration.
It is designed to stay close to upstream i3 behavior while adding a few convenience features
for daily use.

The goal is:
- Predictable tiling behavior
- Keyboard-driven workflow
- Minimal visual noise
- Easy extensibility via simple shell scripts

No external theming frameworks or heavy abstractions are used.

---

## Concept: Application Settings

All user-configurable applications are defined inside the `settings/` directory.

Each file contains **only the binary name**, for example:

```sh
firefox
```

The i3 config itself handles the `exec` logic and simply reads these files.
This keeps configuration clean and avoids hardcoding application names.

If an application does not exist on the system, the installer will warn the user.

---

## Features

- i3 (X11) based setup
- Focus follows mouse
- Simple, readable keybindings
- Keyboard layout switching (e.g. `ch_de` ↔ `us_workman`)
- Keyboard-driven window movement and resizing
- Minimal logout / power overlay
- Multi-monitor friendly (`xrandr`)
- No hidden logic or frameworks

---

## Required Packages (Arch Linux)

### Core
- `i3-wm`
- `xorg-server`
- `xorg-xinit`
- `dmenu` or `rofi`

### Utilities
- `xrandr`
- `setxkbmap`
- `picom` (optional)
- `feh` (optional)
- `playerctl` (optional)
- `brightnessctl` (optional)

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/JGH0/MyI3Config.git
cd MyI3Repo
```

---

### 2. Run the installer

```bash
./install.sh
```

The installer will:

- Ask if you want to install the i3 configuration
- Copy the config to `~/.config/i3`
- Ask which terminal, browser, file manager, and calculator you want to use
- Validate that the chosen applications exist
- Write the selected application names into `settings/*.sh`

If an application is not found, you will be asked again.

---

### 3. Log into i3

When starting i3 for the first time:
- **Do NOT generate a new config**
- Use the installed configuration

---

## packages.txt

The `packages.txt` file contains a suggested list of packages you may want to install.
It is intentionally not installed automatically to keep full user control.

Example:

```bash
sudo pacman -S --needed - < packages.txt
```

---

## Notes

- This configuration is intentionally minimal
- Everything is plain text and easy to understand
- No magic, no hidden behavior
- You are encouraged to fork and modify this setup to your needs
