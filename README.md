# MyI3Config

A minimal, practical window manager configuration that supports both **i3 (X11)** and **Sway (Wayland)**. The configuration is designed to stay close to upstream behavior while adding convenience features for daily use.

---

## Features

- **Dual compatibility**: Works with both i3 (X11) and Sway (Wayland)
- **Focus follows mouse**: Natural window focus behavior
- **Keyboard-driven workflow**: All common actions accessible via keyboard
- **Minimal visual noise**: No bars, no bloat, just windows
- **Environment-aware scripts**: Auto-detect i3 vs Sway and use appropriate tools
- **Easy extensibility**: Simple shell scripts for customization
- **Unified configuration**: One config file for both window managers

---

## Structure

```
MyI3Config/
├── i3/                    # i3-specific configuration and scripts
├── scripts/              # Environment-aware scripts (work in both i3/Sway)
├── settings/             # User application preferences
├── install.sh           # Smart installer with i3/Sway detection
├── packages-common.txt  # Packages shared by both i3 and Sway
├── packages-i3.txt      # i3-specific packages (X11)
└── packages-sway.txt    # Sway-specific packages (Wayland)
```

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/JGH0/MyI3Config.git
cd MyI3Config
```

### 2. Run the installer

```bash
./install.sh
```

The installer will:

1. **Detect your environment**: Auto-detects if you're running i3 or Sway (or lets you choose)
2. **Install packages**: Installs only the necessary packages for your chosen window manager
3. **Configure applications**: Lets you choose your preferred terminal, browser, file manager, and calculator
4. **Set up configuration**: Copies files to `~/.config/MyI3Config` and creates appropriate symlinks

## Package Management

The repository uses three package lists for clean dependency management:

- **`packages-common.txt`**: Applications that work on both i3 and Sway
  - `rofi`, `brightnessctl`, `playerctl`, etc.
- **`packages-i3.txt`**: i3/X11 specific packages
  - `i3-wm`, `xorg-server`, `maim`, `xclip`, `i3lock`, etc.
- **`packages-sway.txt`**: Sway/Wayland specific packages
  - `sway`, `grim`, `slurp`, `wl-clipboard`, `swaylock`, etc.

## Environment-Aware Scripts

The `scripts/` directory contains smart scripts that detect whether they're running under i3 or Sway and use the appropriate tools:

- **`screenshot.sh`**: Uses `maim` + `xclip` on i3, `grim` + `wl-copy` on Sway
- **`display-tool.sh`**: Launches `arandr` on i3, `wdisplays` on Sway
- **`lock.sh`**: Uses `i3lock` on i3, `swaylock` on Sway
- **`keyboard-setup.sh`**: Uses `setxkbmap` on i3, `swaymsg input` on Sway
- **`startup.sh`**: Runs appropriate startup commands for each environment

## Application Settings

All user-configurable applications are defined in the `settings/` directory. Each file contains only the binary name, for example:

```sh
# settings/terminal.sh
kitty
```

The configuration reads these files, keeping your app choices separate from keybindings.

## Switching Between i3 and Sway

If you want to use both window managers:

1. **Run the installer twice**: Once selecting i3, once selecting Sway
2. **Both configs will be installed**: The installer creates symlinks to the same config file
3. **Log out and switch**: Choose your window manager from your display manager

**Note**: The configuration file is written in i3 syntax but uses environment-aware scripts to handle differences between i3 and Sway.

## Keybindings (Common to Both)

| Key Combination | Action |
|----------------|--------|
| `Super + Return` | Terminal |
| `Super + b` | Browser |
| `Super + e` | File manager |
| `Super + Ctrl + c` | Calculator |
| `Super + Ctrl + Return` | Application launcher (rofi) |
| `Super + 1-0` | Switch workspaces |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + q` | Close window |
| `Super + f` | Toggle fullscreen |
| `Super + Shift + s` | Take screenshot |
| `Super + l` | Lock screen |
| `Super + space` | Toggle keyboard layout |
| `Super + Shift + c` | Reload configuration |
| `Super + Shift + r` | Restart window manager |

## Customization

1. **Application preferences**: Edit files in `~/.config/MyI3Config/settings/`
2. **Keybindings**: Edit `~/.config/MyI3Config/i3/config`
3. **Scripts**: Modify `~/.config/MyI3Config/scripts/` for custom behavior
4. **Package lists**: Update the `packages-*.txt` files to add/remove packages

## Troubleshooting

### i3 Issues
- Ensure X11 packages are installed (`packages-i3.txt`)
- Check that `~/.config/i3/config` is symlinked correctly
- Verify X server is running (`startx` or display manager)

### Sway Issues
- Ensure Wayland packages are installed (`packages-sway.txt`)
- Check that `~/.config/sway/config` is symlinked correctly
- Make sure to select Sway from your display manager
- Some applications may need Wayland flags (e.g., `--enable-features=WaylandWindowDecorations`)

### General Issues
- Run `install.sh` again to reinstall
- Check script permissions: `chmod +x ~/.config/MyI3Config/scripts/*.sh`
- Reload configuration: `Super + Shift + c`

## License

This configuration is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**Goal**: Predictable tiling behavior with keyboard-driven workflow, minimal visual noise, and easy extensibility via simple shell scripts.