# MyI3Config

A minimal, practical window manager configuration that supports **i3 (X11)**, **Sway (Wayland)**, and **AeroSpace (macOS)**. The configuration is designed to stay close to upstream behavior while adding convenience features for daily use. All user preferences are now managed via a companion **Tauri settings app**, which stores keybindings and theme settings in JSON files.

---

## Features

- **Triple compatibility**: Works with i3 (X11), Sway (Wayland), and AeroSpace (macOS)
- **Focus follows mouse**: Natural window focus behavior (i3/Sway only)
- **Keyboard-driven workflow**: All common actions accessible via keyboard
- **Minimal visual noise**: No bars, no bloat, just windows
- **Environment-aware scripts**: Auto-detect i3, Sway, or macOS and use appropriate tools
- **Easy extensibility**: Simple shell scripts for customization
- **Unified configuration**: One config file for both i3 and Sway; separate AeroSpace config for macOS
- **Settings manager**: A Tauri app (`MyI3ConfigSettings`) provides a graphical interface to customise keybindings and themes (i3/Sway only).

---

## Structure

```
MyI3Config/
├── i3/                    # i3/sway configuration (main config file)
├── aerospace/             # AeroSpace configuration (macOS)
│   └── aerospace.toml     # AeroSpace main config (place at ~/.aerospace.toml)
├── scripts/               # Environment-aware scripts (work in both i3/Sway)
├── scripts-aerospace/     # macOS-specific scripts (work with AeroSpace)
├── default-keybindings.json   # Default keybinding definitions (used by installer)
├── default-theme.json         # Default theme settings
├── default-workspaces.json    # Default workspace names and assignments
├── default-input.json         # Default input device settings
├── install.sh            # Smart installer with i3/Sway/AeroSpace detection
├── packages-common.txt   # Packages shared by both i3 and Sway
├── packages-i3.txt       # i3-specific packages (X11)
├── packages-sway.txt     # Sway-specific packages (Wayland)
└── packages-aerospace.txt # macOS Homebrew packages
```

User-specific configuration is stored in `~/.config/MyI3Config/`:
- `keybindings.json` - your personal keybindings (managed by the Tauri app)
- `keybindings.conf` - generated i3/sway bindsym lines (automatically updated)
- `theme.json` - your theme preferences
- `theme.conf` - generated i3/sway theme directives
- `scripts/` - your custom scripts (e.g. `lock.sh`, `theme-startup.sh`)

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

The installer will prompt you to select a target:

```
Select target:
1) i3 (Linux / X11)
2) Sway (Linux / Wayland)
3) AeroSpace (macOS)
4) Auto-detect
```

**For i3/Sway**, the installer will:

1. **Detect your environment**: Auto‑detects if you're running i3 or Sway (or lets you choose)
2. **Install packages**: Installs only the necessary packages for your chosen window manager (reads `packages-*.txt`)
3. **Configure applications**: Lets you choose your preferred terminal, browser, file manager, and calculator – these are written into `keybindings.json`
4. **Set up configuration**: Copies all files to `~/.config/MyI3Config` (without overwriting existing user files)
5. **Generate `.conf` files**: Creates `keybindings.conf` and `theme.conf` from the default JSON files so that your config works immediately after installation
6. **Create symlinks**: Links the main config file to `~/.config/i3/config` or `~/.config/sway/config` as appropriate
7. **Make scripts executable**: Ensures all `.sh` files have execute permissions

**For AeroSpace (macOS)**, the installer will:

1. **Install packages**: Installs AeroSpace and other tools via Homebrew (if available)
2. **Copy AeroSpace config**: Places `aerospace/aerospace.toml` at `~/.aerospace.toml`
3. **Make scripts executable**: Ensures all `scripts-aerospace/*.sh` files are executable

After installation, reload i3/Sway (`Super + Shift + C`) to apply the default configuration.

---

## Package Management

The repository uses three package lists for clean dependency management:

- **`packages-common.txt`** - applications that work on both i3 and Sway (e.g. `rofi`, `brightnessctl`, `playerctl`, `jq`)
- **`packages-i3.txt`** - i3/X11 specific packages (e.g. `i3-wm`, `xorg-server`, `maim`, `xclip`, `i3lock`)
- **`packages-sway.txt`** - Sway/Wayland specific packages (e.g. `sway`, `grim`, `slurp`, `wl-clipboard`, `swaylock`, `swaybg`)

---

## The Settings Manager: MyI3ConfigSettings

A separate **Tauri-based graphical application** (`MyI3ConfigSettings`) allows you to easily customise your keybindings and theme without editing text files.

**Features**:

- **Keybindings editor** with live key capture (press a key combination to record it)
- Support for **application**, **window action**, **workspace switch**, **move to workspace**, and **resize** bindings
- Search and filter by type
- **Theme editor** with colour pickers, font autocomplete (with live preview), gap settings, border style, and wallpaper selection (static or animated GIF)
- Automatically updates the JSON files and regenerates the `.conf` snippets
- Includes a **reload button** to apply changes immediately (`i3-msg reload` / `swaymsg reload`)

See the [MyI3ConfigSettings repository](https://github.com/JGH0/MyI3ConfigSettings) for installation and usage instructions.

---

## Environment-Aware Scripts

The `scripts/` directory contains smart scripts that detect whether they're running under i3 or Sway and use the appropriate tools:

- **`screenshot.sh`** - uses `maim` + `xclip` on i3, `grim` + `wl-copy` on Sway
- **`display-tool.sh`** - launches `arandr` on i3, `wdisplays` on Sway
- **`lock.sh`** - uses `i3lock` on i3, `swaylock` on Sway (the theme editor can add a lock image)
- **`keyboard-setup.sh`** - uses `setxkbmap` on i3, `swaymsg input` on Sway
- **`startup.sh`** - runs appropriate startup commands for each environment
- **`theme-startup.sh`** - generated by the theme editor; sets the wallpaper (static or animated)

These scripts are designed to be **user-editable** - changes are preserved by the installer.

---

## Customisation

### Via the Tauri App (recommended)
Launch the `MyI3ConfigSettings` app (after building it) and use the graphical interface to adjust keybindings and theme settings. All changes are written to the JSON files and automatically applied (reload button provided).

### Manual editing
If you prefer to edit files directly:
- **Keybindings**: edit `~/.config/MyI3Config/keybindings.json` (see the [default-keybindings.json](default-keybindings.json) for the schema)
- **Theme**: edit `~/.config/MyI3Config/theme.json`
- **Scripts**: modify any file in `~/.config/MyI3Config/scripts/`

After manual changes, run `jq` (or let the Tauri app regenerate the `.conf` files) and reload i3/Sway.

---

## Keybindings (Default)

The default keybindings are defined in [`default-keybindings.json`](default-keybindings.json). The four application-specific commands (terminal, browser, file manager, calculator) are set during installation; all others are fixed. After installation you can customise any binding via the Tauri app.

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

## AeroSpace (macOS)

[AeroSpace](https://github.com/nikitabobko/AeroSpace) is an i3-like tiling window manager for macOS. This repo includes a configuration that mirrors the i3/sway setup as closely as possible.

You can install the configuration via the installer (option 3 - AeroSpace):

```bash
./install.sh
# Select: 3) AeroSpace (macOS)
```

Or manually:

```bash
# 1. Install AeroSpace via Homebrew
brew install --cask nikitabobko/tap/aerospace

# 2. Copy the config
cp aerospace/aerospace.toml ~/.aerospace.toml

# 3. Make scripts executable
chmod +x scripts-aerospace/*.sh

# 4. Reload AeroSpace
aerospace reload-config
```

### Keybinding Mapping

The AeroSpace config uses **cmd (⌘)** as the primary modifier, which maps to the same physical position as the Super key on a typical keyboard. This keeps your muscle memory consistent across platforms.

| i3/Sway Binding         | AeroSpace Binding        | Action                     |
|--------------------------|--------------------------|----------------------------|
| `$mod+Return`           | `cmd-return`            | Terminal                   |
| `$mod+b`                | `cmd-b`                 | Browser                    |
| `$mod+e`                | `cmd-e`                 | File manager               |
| `$mod+q`                | `cmd-q`                 | Close window               |
| `$mod+f`                | `cmd-f`                 | Fullscreen toggle          |
| `$mod+t`                | `cmd-t`                 | Floating toggle            |
| `$mod+j`                | `cmd-j`                 | Cycle tiling layout        |
| `$mod+1-9`              | `cmd-1-9`               | Switch workspace           |
| `$mod+0`                | `cmd-0`                 | Switch workspace 10        |
| `$mod+Shift+1-9`        | `shift-cmd-1-9`         | Move to workspace          |
| `$mod+Shift+0`          | `shift-cmd-0`           | Move to workspace 10       |
| `$mod+arrows`           | `cmd-arrows`            | Focus direction            |
| `$mod+Ctrl+arrows`      | `ctrl-cmd-arrows`       | Move window                |
| `$mod+Shift+arrows`     | `shift-cmd-arrows`      | Resize window              |
| `$mod+Shift+s`          | `shift-cmd-s`           | Screenshot                 |
| `$mod+l`                | `cmd-l`                 | Lock screen                |
| `$mod+space`            | `cmd-space`             | Keyboard layout toggle     |
| `$mod+Ctrl+q`           | `ctrl-cmd-q`            | Power menu (`overlay-menu`) |

> **Note**: AeroSpace uses its own emulated workspaces rather than macOS Spaces. This means no SIP disabling required, and faster workspace switching.

### macOS Scripts

The `scripts-aerospace/` directory contains macOS-native equivalents of the i3/sway scripts:

| Script                   | i3/Sway                              | macOS/AeroSpace                  |
|--------------------------|--------------------------------------|----------------------------------|
| `screenshot.sh`          | `maim` / `grim` + clipboard          | `screencapture -i -c` (built-in) |
| `lock.sh`                | `i3lock` / `swaylock`                | `osascript` → sleep              |
| `display-tool.sh`        | `arandr` / `wdisplays`              | System Settings → Displays       |
| `startup.sh`             | `xsetroot` / `swaymsg`              | macOS `defaults write`           |
| `cycle-layout.sh`        | `setxkbmap` / `swaymsg input`       | Toggle macOS input sources       |

### Caveats

- **No theme/color support**: AeroSpace does not support window borders or color themes (by design). The `theme.json` → `theme.conf` pipeline does not apply on macOS.
- **No settings app**: The Tauri settings app (`MyI3ConfigSettings`) is Linux-only. Edit `~/.aerospace.toml` directly on macOS.
- **Shell/application paths**: The AeroSpace config assumes Kitty, Firefox, Finder, etc. Adjust paths in `~/.aerospace.toml` to match your installed applications.

## Switching Between i3 and Sway

If you want to use both window managers:

1. **Run the installer twice**: once selecting i3, once selecting Sway.
2. **Both configs will be installed**: the installer creates symlinks to the same config file for each.
3. **Log out and switch**: choose your window manager from your display manager.

**Note**: The configuration file is written in i3 syntax but uses environment-aware scripts to handle differences between i3 and Sway.

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
- Run `install.sh` again - it will not overwrite your existing user files.
- Check script permissions: `chmod +x ~/.config/MyI3Config/scripts/*.sh`
- Reload configuration: `Super + Shift + C`
- If the wallpaper does not appear, ensure the required tools (`feh` for i3, `swaybg` for Sway) are installed.
- For animated wallpapers, install `mpvpaper` (Sway) or `xwinwrap` + `mpv` (i3) - the theme editor will show a warning if they are missing.

---

## License

This configuration is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

**Goal**: Predictable tiling behaviour with a keyboard-driven workflow, minimal visual noise, and easy customisation through a modern graphical settings app.
