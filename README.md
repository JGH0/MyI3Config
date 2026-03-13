# MyI3Config

A minimal, practical window manager configuration that supports both **i3 (X11)** and **Sway (Wayland)**. The configuration is designed to stay close to upstream behavior while adding convenience features for daily use. All user preferences are now managed via a companion **Tauri settings app**, which stores keybindings and theme settings in JSON files.

---

## Features

- **Dual compatibility**: Works with both i3 (X11) and Sway (Wayland)
- **Focus follows mouse**: Natural window focus behavior
- **Keyboard-driven workflow**: All common actions accessible via keyboard
- **Minimal visual noise**: No bars, no bloat, just windows
- **Environment-aware scripts**: Auto-detect i3 vs Sway and use appropriate tools
- **Easy extensibility**: Simple shell scripts for customization
- **Unified configuration**: One config file for both window managers
- **Settings manager**: A Tauri app (`MyI3ConfigSettings`) provides a graphical interface to customise keybindings and themes.

---

## Structure

```
MyI3Config/
├── i3/                    # i3‑specific configuration (main config file)
├── scripts/              # Environment‑aware scripts (work in both i3/Sway)
├── default-keybindings.json   # Default keybinding definitions (used by installer)
├── default-theme.json         # Default theme settings
├── install.sh            # Smart installer with i3/Sway detection
├── packages-common.txt   # Packages shared by both i3 and Sway
├── packages-i3.txt       # i3‑specific packages (X11)
└── packages-sway.txt     # Sway‑specific packages (Wayland)
```

User‑specific configuration is stored in `~/.config/MyI3Config/`:
- `keybindings.json` – your personal keybindings (managed by the Tauri app)
- `keybindings.conf` – generated i3/sway bindsym lines (automatically updated)
- `theme.json` – your theme preferences
- `theme.conf` – generated i3/sway theme directives
- `scripts/` – your custom scripts (e.g. `lock.sh`, `theme-startup.sh`)

These user files are **ignored by git** (see `.gitignore`) so your personal settings never get committed.

---

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

1. **Detect your environment**: Auto‑detects if you’re running i3 or Sway (or lets you choose)
2. **Install packages**: Installs only the necessary packages for your chosen window manager (reads `packages-*.txt`)
3. **Configure applications**: Lets you choose your preferred terminal, browser, file manager, and calculator – these are written into `keybindings.json`
4. **Set up configuration**: Copies all files to `~/.config/MyI3Config` (without overwriting existing user files)
5. **Generate `.conf` files**: Creates `keybindings.conf` and `theme.conf` from the default JSON files so that your config works immediately after installation
6. **Create symlinks**: Links the main config file to `~/.config/i3/config` or `~/.config/sway/config` as appropriate
7. **Make scripts executable**: Ensures all `.sh` files have execute permissions

After installation, reload i3/Sway (`Super + Shift + C`) to apply the default configuration.

---

## Package Management

The repository uses three package lists for clean dependency management:

- **`packages-common.txt`** – applications that work on both i3 and Sway (e.g. `rofi`, `brightnessctl`, `playerctl`, `jq`)
- **`packages-i3.txt`** – i3/X11 specific packages (e.g. `i3-wm`, `xorg-server`, `maim`, `xclip`, `i3lock`)
- **`packages-sway.txt`** – Sway/Wayland specific packages (e.g. `sway`, `grim`, `slurp`, `wl-clipboard`, `swaylock`, `swaybg`)

---

## The Settings Manager: MyI3ConfigSettings

A separate **Tauri‑based graphical application** (`MyI3ConfigSettings`) allows you to easily customise your keybindings and theme without editing text files.

**Features**:

- **Keybindings editor** with live key capture (press a key combination to record it)
- Support for **application**, **window action**, **workspace switch**, **move to workspace**, and **resize** bindings
- Search and filter by type
- **Theme editor** with colour pickers, font autocomplete (with live preview), gap settings, border style, and wallpaper selection (static or animated GIF)
- Automatically updates the JSON files and regenerates the `.conf` snippets
- Includes a **reload button** to apply changes immediately (`i3-msg reload` / `swaymsg reload`)

See the [MyI3ConfigSettings repository](https://github.com/JGH0/MyI3ConfigSettings) for installation and usage instructions.

---

## Environment‑Aware Scripts

The `scripts/` directory contains smart scripts that detect whether they’re running under i3 or Sway and use the appropriate tools:

- **`screenshot.sh`** – uses `maim` + `xclip` on i3, `grim` + `wl-copy` on Sway
- **`display-tool.sh`** – launches `arandr` on i3, `wdisplays` on Sway
- **`lock.sh`** – uses `i3lock` on i3, `swaylock` on Sway (the theme editor can add a lock image)
- **`keyboard-setup.sh`** – uses `setxkbmap` on i3, `swaymsg input` on Sway
- **`startup.sh`** – runs appropriate startup commands for each environment
- **`theme-startup.sh`** – generated by the theme editor; sets the wallpaper (static or animated)

These scripts are designed to be **user‑editable** – changes are preserved by the installer.

---

## Customisation

### Via the Tauri App (recommended)
Launch the `MyI3ConfigSettings` app (after building it) and use the graphical interface to adjust keybindings and theme settings. All changes are written to the JSON files and automatically applied (reload button provided).

### Manual editing
If you prefer to edit files directly:
- **Keybindings**: edit `~/.config/MyI3Config/keybindings.json` (see the [default‑keybindings.json](default-keybindings.json) for the schema)
- **Theme**: edit `~/.config/MyI3Config/theme.json`
- **Scripts**: modify any file in `~/.config/MyI3Config/scripts/`

After manual changes, run `jq` (or let the Tauri app regenerate the `.conf` files) and reload i3/Sway.

---

## Keybindings (Default)

The default keybindings are defined in [`default-keybindings.json`](default-keybindings.json). The four application‑specific commands (terminal, browser, file manager, calculator) are set during installation; all others are fixed. After installation you can customise any binding via the Tauri app.

A summary of the most important default bindings:

| Key Combination               | Action                               |
|-------------------------------|--------------------------------------|
| `Super + Return`              | Terminal                             |
| `Super + b`                   | Browser                              |
| `Super + e`                   | File manager                         |
| `Super + Ctrl + c`            | Calculator                           |
| `Super + Ctrl + Return`       | Application launcher (rofi)          |
| `Super + 1-9`                 | Switch to workspace 1-9              |
| `Super + 0`                   | Switch to workspace 10               |
| `Super + Shift + 1-9`         | Move window to workspace 1-9         |
| `Super + Shift + 0`           | Move window to workspace 10          |
| `Super + q`                   | Kill focused window                  |
| `Super + f`                   | Toggle fullscreen                    |
| `Super + Shift + s`           | Take screenshot                      |
| `Super + l`                   | Lock screen                          |
| `Super + space`               | Toggle keyboard layout               |
| `Super + Shift + C`           | Reload configuration                 |
| `Super + Shift + R`           | Restart window manager               |

(For a complete list, open the keybindings editor in the Tauri app.)

---

## Switching Between i3 and Sway

If you want to use both window managers:

1. **Run the installer twice**: once selecting i3, once selecting Sway.
2. **Both configs will be installed**: the installer creates symlinks to the same config file for each.
3. **Log out and switch**: choose your window manager from your display manager.

**Note**: The configuration file is written in i3 syntax but uses environment‑aware scripts to handle differences between i3 and Sway.

---

## Troubleshooting

### i3 Issues
- Ensure X11 packages are installed (`packages-i3.txt`).
- Check that `~/.config/i3/config` is symlinked correctly.
- Verify X server is running (`startx` or display manager).

### Sway Issues
- Ensure Wayland packages are installed (`packages-sway.txt`).
- Check that `~/.config/sway/config` is symlinked correctly.
- Make sure to select Sway from your display manager.
- Some applications may need Wayland flags (e.g. `--enable-features=WaylandWindowDecorations`).

### General Issues
- Run `install.sh` again – it will not overwrite your existing user files.
- Check script permissions: `chmod +x ~/.config/MyI3Config/scripts/*.sh`
- Reload configuration: `Super + Shift + C`
- If the wallpaper does not appear, ensure the required tools (`feh` for i3, `swaybg` for Sway) are installed.
- For animated wallpapers, install `mpvpaper` (Sway) or `xwinwrap` + `mpv` (i3) – the theme editor will show a warning if they are missing.

---

## License

This configuration is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**Goal**: Predictable tiling behaviour with a keyboard‑driven workflow, minimal visual noise, and easy customisation through a modern graphical settings app.
