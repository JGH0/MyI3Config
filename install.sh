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

# Detect if running in Sway
is_sway() {
    [ -n "$SWAYSOCK" ] || pgrep -x sway >/dev/null 2>&1
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required but not installed."
        if ask "Would you like to install jq now?"; then
            sudo pacman -S --needed jq
        else
            echo "Please install jq manually and re-run the installer."
            exit 1
        fi
    fi
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
# 1/3: Install packages
# ----------------------------
echo
echo "[1/3] Installing packages..."

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

# Ensure jq is available for subsequent steps
check_jq

# ----------------------------
# 2/3: Copy configuration files
# ----------------------------
echo
echo "[2/3] Installing MyI3Config..."

# Copy all files from the repo, but don't overwrite existing user files
cp -rn "$REPO_DIR/." "$CFG_ROOT" 2>/dev/null || true

# Generate conf files from default JSONs (if they exist)
if [ -f "$CFG_ROOT/default-keybindings.json" ] && [ ! -f "$CFG_ROOT/keybindings.json" ]; then
    cp "$CFG_ROOT/default-keybindings.json" "$CFG_ROOT/keybindings.json"
fi
if [ -f "$CFG_ROOT/default-theme.json" ] && [ ! -f "$CFG_ROOT/theme.json" ]; then
    cp "$CFG_ROOT/default-theme.json" "$CFG_ROOT/theme.json"
fi

# Generate .conf files
generate_keybindings_conf
generate_theme_conf

# Make all scripts executable
find "$CFG_ROOT/scripts" -type f -name "*.sh" -exec chmod +x {} \;

# Ensure lock.sh exists
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
# Optional: Install settings app
# ----------------------------
echo
echo "[3/3] Optional: Install the Tauri settings app (MyI3ConfigSettings)"
if ask "Would you like to clone and build the settings app?"; then
    echo "Cloning MyI3ConfigSettings..."
    git clone https://github.com/JGH0/MyI3ConfigSettings.git /tmp/MyI3ConfigSettings
    cd /tmp/MyI3ConfigSettings
    echo "Building (this may take a while)..."
    if npm install && cargo tauri build; then
        # Find the built binary (may be lowercase or mixed case)
        BINARY_PATH=$(find src-tauri/target/release -maxdepth 1 -type f -executable \( -name "myi3configsettings" -o -name "MyI3ConfigSettings" \) | head -n1)
        if [ -n "$BINARY_PATH" ]; then
            BIN_DIR="$HOME/.local/bin"
            mkdir -p "$BIN_DIR"
            cp "$BINARY_PATH" "$BIN_DIR/"
            echo "Settings app installed to $BIN_DIR/$(basename "$BINARY_PATH")"
            echo "You can run it from terminal or create a desktop entry."
        else
            echo "Error: Could not find built binary."
        fi
    else
        echo "Error: Failed to build settings app. Please check the logs above."
        echo "You can manually install it later from:"
        echo "  https://github.com/JGH0/MyI3ConfigSettings"
    fi
    cd - >/dev/null
    rm -rf /tmp/MyI3ConfigSettings
else
    echo "Skipping settings app installation."
    echo "You can manually install it later from:"
    echo "  https://github.com/JGH0/MyI3ConfigSettings"
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
echo "The Tauri settings app (if installed) will manage your keybindings and theme."
echo "Run 'MyI3ConfigSettings' to customise further."
