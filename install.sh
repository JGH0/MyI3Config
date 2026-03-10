#!/usr/bin/env bash
set -e

# ----------------------------
# MyI3Config Installer
# ----------------------------

# Detect repository directory dynamically
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_ROOT="$HOME/.config/MyI3Config"

# ----------------------------
# Functions
# ----------------------------

# Ask yes/no question
ask() {
    printf "%s [y/N]: " "$1"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# Ask for application and verify it exists in PATH
ask_app() {
    local label="$1"
    local default="$2"
    local app
    local first_run=true

    while true; do
        if [ "$first_run" = true ]; then
            read -rp "$label (default: $default): " app
            first_run=false
        else
            read -rp "Enter a different command or 'skip' to continue anyway: " app
        fi

        if [ -z "$app" ]; then
            if [ "$first_run" = false ]; then
                echo "  Press Enter again to skip, or type 'skip'"
                continue
            fi
            app="$default"
        fi

        if [ "$app" = "skip" ]; then
            echo "  Using '$default' (not verified)"
            echo "$default"
            return
        fi

        if command -v "${app%% *}" >/dev/null 2>&1; then
            echo "$app"
            return
        else
            echo "✗ '$app' not found in PATH"
            if [ "$first_run" = true ]; then
                echo "  Install it with: sudo pacman -S ${app%% *}"
                echo "  Or choose a different application"
            fi
        fi
    done
}

# Detect if running in Sway
is_sway() {
    [ -n "$SWAYSOCK" ] || pgrep -x sway >/dev/null 2>&1
}

# Update keybindings.json with user-chosen apps (preserve existing entries)
update_keybindings_with_apps() {
    local json_file="$CFG_ROOT/keybindings.json"
    local tmp_file="$CFG_ROOT/keybindings.json.tmp"

    if [ ! -f "$json_file" ]; then
        # No existing file, create from default and substitute apps
        cp "$REPO_DIR/default-keybindings.json" "$json_file"
    fi

    # Use jq to replace the command fields for the specific app bindings
    # This requires jq installed (should be, it's in packages)
    jq --arg term "$1" \
       --arg browser "$2" \
       --arg fm "$3" \
       --arg calc "$4" \
       'map(if .keyCombo == "$mod+Return" and .type == "app" then .command = $term
            elif .keyCombo == "$mod+b" and .type == "app" then .command = $browser
            elif .keyCombo == "$mod+e" and .type == "app" then .command = $fm
            elif .keyCombo == "Ctrl+$mod+c" and .type == "app" then .command = $calc
            else . end)' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"
}

# Generate keybindings.conf from keybindings.json
generate_keybindings_conf() {
    local json_file="$CFG_ROOT/keybindings.json"
    local conf_file="$CFG_ROOT/keybindings.conf"
    if [ ! -f "$json_file" ]; then
        echo "Warning: keybindings.json not found, skipping keybindings.conf generation"
        return
    fi
    # Use jq to output bindsym lines
    jq -r '.[] |
        if .type == "app" then
            "bindsym " + .keyCombo + " exec " + .command
        elif .type == "window" then
            "bindsym " + .keyCombo + " " + .action
        elif .type == "workspace" then
            "bindsym " + .keyCombo + " workspace " + (if .workspaceNum == 0 then "10" else .workspaceNum | tostring end)
        elif .type == "move-to-workspace" then
            "bindsym " + .keyCombo + " move container to workspace " + (if .workspaceNum == 0 then "10" else .workspaceNum | tostring end)
        elif .type == "resize" then
            "bindsym " + .keyCombo + " resize " + .resizeDir + " " + (.resizeAmount | tostring) + " " + .resizeUnit
        else
            empty
        end
    ' "$json_file" > "$conf_file"
    echo "Generated $conf_file"
}

# Generate theme.conf from theme.json
generate_theme_conf() {
    local json_file="$CFG_ROOT/theme.json"
    local conf_file="$CFG_ROOT/theme.conf"
    if [ ! -f "$json_file" ]; then
        echo "Warning: theme.json not found, skipping theme.conf generation"
        return
    fi
    # Build theme.conf lines
    {
        jq -r '.font | "font pango:" + .' "$json_file"
        jq -r 'if .gapsInner > 0 or .gapsOuter > 0 then
                "gaps inner \(.gapsInner)\ngaps outer \(.gapsOuter)"
               else empty end' "$json_file"
        jq -r 'if .borderStyle == "pixel" then
                "default_border pixel \(.borderPixelWidth)"
               else
                "default_border \(.borderStyle)" end' "$json_file"
        jq -r '"floating_modifier " + .floatingModifier' "$json_file"
        jq -r '"focus_follows_mouse " + .focusFollowsMouse' "$json_file"
        jq -r '"client.focused \(.colors.focused.border) \(.colors.focused.background) \(.colors.focused.text) \(.colors.focused.indicator)"' "$json_file"
        jq -r '"client.unfocused \(.colors.unfocused.border) \(.colors.unfocused.background) \(.colors.unfocused.text)"' "$json_file"
        jq -r '"client.urgent \(.colors.urgent.border) \(.colors.urgent.background) \(.colors.urgent.text)"' "$json_file"
        if jq -e '.wallpaper' "$json_file" >/dev/null && [ "$(jq -r '.wallpaper' "$json_file")" != "" ]; then
            echo "exec --no-startup-id ~/.config/MyI3Config/scripts/theme-startup.sh"
        fi
    } > "$conf_file"
    echo "Generated $conf_file"
}

# ----------------------------
# Installer
# ----------------------------

echo "=== MyI3Config installer ==="
echo

# Ask if installing for i3 or Sway
echo "Select window manager:"
echo "1) i3 (X11)"
echo "2) Sway (Wayland)"
echo "3) Auto-detect"
read -rp "Choice (1/2/3): " wm_choice

case "$wm_choice" in
    1) WM="i3" ;;
    2) WM="sway" ;;
    3)
        if is_sway; then
            WM="sway"
            echo "Auto-detected: Sway"
        else
            WM="i3"
            echo "Auto-detected: i3"
        fi
        ;;
    *)
        echo "Invalid choice, defaulting to i3"
        WM="i3"
        ;;
esac

echo "Installing for: $WM"
echo

if ! ask "Install this configuration?"; then
    echo "Aborted."
    exit 0
fi

mkdir -p "$HOME/.config"
mkdir -p "$CFG_ROOT"
mkdir -p "$CFG_ROOT/scripts"

# ----------------------------
# 1/4: Install packages
# ----------------------------
echo
echo "[1/4] Installing packages..."

PACKAGES=""

if [ -f "$REPO_DIR/packages-common.txt" ]; then
    echo "  Using split package configuration"
    COMMON_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-common.txt" | tr '\n' ' ')
    PACKAGES="$PACKAGES $COMMON_PACKAGES"

    if [ "$WM" = "sway" ] && [ -f "$REPO_DIR/packages-sway.txt" ]; then
        echo "  Installing Sway packages..."
        SWAY_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-sway.txt" | tr '\n' ' ')
        PACKAGES="$PACKAGES $SWAY_PACKAGES"
    elif [ "$WM" = "i3" ] && [ -f "$REPO_DIR/packages-i3.txt" ]; then
        echo "  Installing i3 packages..."
        I3_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-i3.txt" | tr '\n' ' ')
        PACKAGES="$PACKAGES $I3_PACKAGES"
    else
        echo "  Warning: No $WM-specific package file found"
    fi
else
    echo "  Using unified packages.txt"
    PACKAGES=$(grep -v '^#' "$REPO_DIR/packages.txt" | tr '\n' ' ')
fi

if [ -n "$PACKAGES" ]; then
    UNIQUE_PACKAGES=$(echo "$PACKAGES" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo "  Installing: $UNIQUE_PACKAGES"
    sudo pacman -S --needed $UNIQUE_PACKAGES || {
        echo "  Some packages might have failed to install. Continuing..."
    }
else
    echo "  No packages to install."
fi

# ----------------------------
# 2/4: Choose applications
# ----------------------------
echo
echo "[2/4] Choose applications..."
TERMINAL=$(ask_app "Terminal" "kitty")
BROWSER=$(ask_app "Browser" "firefox")
FILEMANAGER=$(ask_app "File manager" "nautilus")
CALCULATOR=$(ask_app "Calculator" "gnome-calculator")

# ----------------------------
# 3/4: Copy static config files (preserve user files)
# ----------------------------
echo
echo "[3/4] Installing MyI3Config..."

# Copy all files from the repo, but don't overwrite existing user files
cp -rn "$REPO_DIR/." "$CFG_ROOT" 2>/dev/null || true

# ----------------------------
# 4/4: Generate/update user configuration
# ----------------------------
echo
echo "[4/4] Setting up user configuration..."

# Create default keybindings.json if it doesn't exist
if [ ! -f "$CFG_ROOT/keybindings.json" ]; then
    cp "$REPO_DIR/default-keybindings.json" "$CFG_ROOT/keybindings.json"
fi

# Update the app commands in keybindings.json
update_keybindings_with_apps "$TERMINAL" "$BROWSER" "$FILEMANAGER" "$CALCULATOR"

# Create default theme.json if it doesn't exist
if [ ! -f "$CFG_ROOT/theme.json" ]; then
    cp "$REPO_DIR/default-theme.json" "$CFG_ROOT/theme.json"
fi

# Generate conf files from JSON
generate_keybindings_conf
generate_theme_conf

# Make all scripts executable
find "$CFG_ROOT/scripts" -type f -name "*.sh" -exec chmod +x {} \;

# Ensure lock.sh is executable (it will be if it exists)
# If lock.sh doesn't exist, create a default one
if [ ! -f "$CFG_ROOT/scripts/lock.sh" ]; then
    cat > "$CFG_ROOT/scripts/lock.sh" <<'EOF'
#!/bin/bash
if [ -n "$SWAYSOCK" ]; then
    swaylock
else
    i3lock
fi
EOF
    chmod +x "$CFG_ROOT/scripts/lock.sh"
fi

# ----------------------------
# Create symlink for config
# ----------------------------
echo
echo "Linking config..."

if [ "$WM" = "sway" ]; then
    SWAY_DIR="$HOME/.config/sway"
    mkdir -p "$SWAY_DIR"
    ln -sf "$CFG_ROOT/i3/config" "$SWAY_DIR/config"
    echo "Linked: $SWAY_DIR/config → $CFG_ROOT/i3/config"
    echo
    echo "Note: Your config is written for i3. For Sway, you may need to:"
    echo "  1. Replace X11 commands (xrandr, xsetroot, etc.) with Wayland equivalents"
    echo "  2. Install Sway-specific tools: grim, slurp, wl-clipboard, etc."
    echo "  3. Update screenshot and display scripts in ~/.config/MyI3Config/scripts/"
else
    I3_DIR="$HOME/.config/i3"
    mkdir -p "$I3_DIR"
    ln -sf "$CFG_ROOT/i3/config" "$I3_DIR/config"
    echo "Linked: $I3_DIR/config → $CFG_ROOT/i3/config"
fi

# ----------------------------
# Done
# ----------------------------
echo
echo "✓ Done"
echo

if [ "$WM" = "sway" ]; then
    echo "For Sway, reload with: Super + Shift + C"
    echo "Make sure to log out and select Sway from your display manager"
else
    echo "For i3, reload with: Super + Shift + C"
fi
echo
echo "The Tauri settings app will manage your keybindings and theme."
echo "Run 'MyI3ConfigSettings' (or the built app) to customise further."