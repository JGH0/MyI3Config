#!/usr/bin/env bash
set -e

# ----------------------------
# MyI3Config Installer
# ----------------------------

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_ROOT="$HOME/.config/MyI3Config"

# ----------------------------
# Functions
# ----------------------------

ask() {
    printf "%s [y/N]: " "$1"
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

is_sway() {
    [ -n "$SWAYSOCK" ] || pgrep -x sway >/dev/null 2>&1
}

# Detect package manager and install packages
install_packages() {
    local packages="$1"
    if [ -z "$packages" ]; then
        return
    fi

    if command -v pacman &>/dev/null; then
        echo "  Installing with pacman..."
        sudo pacman -S --needed $packages || echo "  Some packages failed. Continuing..."
    elif command -v apt-get &>/dev/null; then
        echo "  Installing with apt..."
        sudo apt-get update
        sudo apt-get install -y $packages || echo "  Some packages failed. Continuing..."
    elif command -v dnf &>/dev/null; then
        echo "  Installing with dnf..."
        sudo dnf install -y $packages || echo "  Some packages failed. Continuing..."
    elif command -v zypper &>/dev/null; then
        echo "  Installing with zypper..."
        sudo zypper install -y $packages || echo "  Some packages failed. Continuing..."
    elif command -v yum &>/dev/null; then
        echo "  Installing with yum..."
        sudo yum install -y $packages || echo "  Some packages failed. Continuing..."
    else
        echo "  No supported package manager found. Please install the following packages manually:"
        echo "  $packages"
        echo "  Continuing anyway..."
    fi
}

check_jq() {
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required but not installed."
        if ask "Would you like to install jq now?"; then
            install_packages "jq"
        else
            echo "Please install jq manually and re-run the installer."
            exit 1
        fi
    fi
}

generate_keybindings_conf() {
    local json_file="$CFG_ROOT/keybindings.json"
    local conf_file="$CFG_ROOT/keybindings.conf"
    [ ! -f "$json_file" ] && return
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
        else empty end
    ' "$json_file" > "$conf_file"
    echo "Generated $conf_file"
}

generate_theme_conf() {
    local json_file="$CFG_ROOT/theme.json"
    local conf_file="$CFG_ROOT/theme.conf"
    [ ! -f "$json_file" ] && return
    {
        jq -r '.font | "font pango:" + .' "$json_file"
        jq -r 'if .gapsInner > 0 or .gapsOuter > 0 then
                "gaps inner \(.gapsInner)\ngaps outer \(.gapsOuter)"
               else empty end' "$json_file"
        jq -r 'if .borderStyle == "pixel" then
                "default_border pixel \(.borderPixelWidth)"
               else "default_border \(.borderStyle)" end' "$json_file"
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

generate_input_conf() {
    local json_file="$CFG_ROOT/input.json"
    local conf_file="$CFG_ROOT/input.conf"
    [ ! -f "$json_file" ] && return
    {
        jq -r '
            "input type:keyboard {",
            "    repeat_rate \(.keyboard.repeatRate)",
            "    repeat_delay \(.keyboard.repeatDelay)",
            if .keyboard.xkbModel and .keyboard.xkbModel != "" then
                "    xkb_model \(.keyboard.xkbModel)"
            else empty end,
            if .keyboard.xkbOptions and .keyboard.xkbOptions != "" then
                "    xkb_options \(.keyboard.xkbOptions)"
            else empty end,
            if .keyboard.xkbNumlock then
                "    xkb_numlock enabled"
            else empty end,
            if .layouts | length > 0 then
                "    xkb_layout " + (.layouts | map(.layout) | join(",")),
                "    xkb_variant " + (.layouts | map(.variant // "") | join(","))
            else empty end,
            "}",
            "input type:touchpad {",
            "    accel_profile \(.mouse.accelProfile)",
            "    pointer_accel \(.mouse.accelSpeed)",
            "    natural_scroll \(if .mouse.naturalScroll then "enabled" else "disabled" end)",
            "    tap \(if .mouse.tapToClick then "enabled" else "disabled" end)",
            "    left_handed \(if .mouse.leftHanded then "enabled" else "disabled" end)",
            "    dwt \(if .mouse.dwt then "enabled" else "disabled" end)",
            "    scroll_method \(.mouse.scrollMethod)",
            if .mouse.scrollMethod == "on_button_down" then
                "    scroll_button \(.mouse.scrollButton)"
            else empty end,
            "    tap_button_map \(.mouse.tapButtonMap)",
            "    drag_lock \(if .mouse.dragLock then "enabled" else "disabled" end)",
            "    middle_emulation \(if .mouse.middleEmulation then "enabled" else "disabled" end)",
            "    click_method \(.mouse.clickMethod)",
            "}"
        ' "$json_file"
    } > "$conf_file"
    echo "Generated $conf_file"
}

generate_workspaces_conf() {
    local json_file="$CFG_ROOT/workspaces.json"
    local conf_file="$CFG_ROOT/workspaces.conf"
    [ ! -f "$json_file" ] && return
    {
        jq -r '.names | to_entries[] | select(.value != .key) | "workspace " + .key + " name \"" + .value + "\""' "$json_file"
        jq -r '.assignments[] | "assign [class=\"" + .appClass + "\"] workspace " + (.workspace | tostring)' "$json_file"
    } > "$conf_file"
    echo "Generated $conf_file"
}

ensure_include_line() {
    local conf_file="$1"
    local include_line="include ~/.config/MyI3Config/${conf_file}.conf"
    local main_config="$CFG_ROOT/i3/config"
    if [ -f "$main_config" ]; then
        if ! grep -q "$include_line" "$main_config"; then
            # Insert after the keybindings include or at the end
            sed -i "/include.*keybindings\.conf/a $include_line" "$main_config" 2>/dev/null ||
            echo "$include_line" >> "$main_config"
            echo "Added $include_line to main config."
        fi
    fi
}

# ----------------------------
# Installer
# ----------------------------

echo "=== MyI3Config installer ==="
echo

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
    COMMON_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-common.txt" | tr '\n' ' ')
    PACKAGES="$PACKAGES $COMMON_PACKAGES"
    if [ "$WM" = "sway" ] && [ -f "$REPO_DIR/packages-sway.txt" ]; then
        SWAY_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-sway.txt" | tr '\n' ' ')
        PACKAGES="$PACKAGES $SWAY_PACKAGES"
    elif [ "$WM" = "i3" ] && [ -f "$REPO_DIR/packages-i3.txt" ]; then
        I3_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-i3.txt" | tr '\n' ' ')
        PACKAGES="$PACKAGES $I3_PACKAGES"
    fi
else
    PACKAGES=$(grep -v '^#' "$REPO_DIR/packages.txt" | tr '\n' ' ')
fi

if [ -n "$PACKAGES" ]; then
    UNIQUE_PACKAGES=$(echo "$PACKAGES" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    echo "  Installing: $UNIQUE_PACKAGES"
    install_packages "$UNIQUE_PACKAGES"
else
    echo "  No packages to install."
fi

check_jq

# ----------------------------
# 2/3: Copy configuration files
# ----------------------------
echo
echo "[2/3] Installing MyI3Config..."

cp -rn "$REPO_DIR/." "$CFG_ROOT" 2>/dev/null || true

# Create default JSONs if missing
[ -f "$CFG_ROOT/default-keybindings.json" ] && [ ! -f "$CFG_ROOT/keybindings.json" ] && \
    cp "$CFG_ROOT/default-keybindings.json" "$CFG_ROOT/keybindings.json"
[ -f "$CFG_ROOT/default-theme.json" ] && [ ! -f "$CFG_ROOT/theme.json" ] && \
    cp "$CFG_ROOT/default-theme.json" "$CFG_ROOT/theme.json"
[ -f "$CFG_ROOT/default-input.json" ] && [ ! -f "$CFG_ROOT/input.json" ] && \
    cp "$CFG_ROOT/default-input.json" "$CFG_ROOT/input.json"
[ -f "$CFG_ROOT/default-workspaces.json" ] && [ ! -f "$CFG_ROOT/workspaces.json" ] && \
    cp "$CFG_ROOT/default-workspaces.json" "$CFG_ROOT/workspaces.json"

# Generate .conf files
generate_keybindings_conf
generate_theme_conf
generate_input_conf
generate_workspaces_conf

# Ensure include lines are in main config
for f in keybindings theme input workspaces; do
    ensure_include_line "$f"
done

# Make scripts executable
find "$CFG_ROOT/scripts" -type f -name "*.sh" -exec chmod +x {} \;

# Default lock.sh if missing
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
# 3/3: Symlink config
# ----------------------------
echo
echo "Linking config..."

if [ "$WM" = "sway" ]; then
    SWAY_DIR="$HOME/.config/sway"
    mkdir -p "$SWAY_DIR"
    ln -sf "$CFG_ROOT/i3/config" "$SWAY_DIR/config"
    echo "Linked: $SWAY_DIR/config → $CFG_ROOT/i3/config"
else
    I3_DIR="$HOME/.config/i3"
    mkdir -p "$I3_DIR"
    ln -sf "$CFG_ROOT/i3/config" "$I3_DIR/config"
    echo "Linked: $I3_DIR/config → $CFG_ROOT/i3/config"
fi

# ----------------------------
# Optional: Install settings app (pre‑built)
# ----------------------------
echo
echo "[Optional] Install the Tauri settings app (MyI3ConfigSettings)"
if ask "Would you like to install the settings app?"; then
    RELEASE_URL="https://github.com/JGH0/MyI3ConfigSettings/releases/download/v1.0.0/myi3configsettings-1.0.0-x86_64.tar.gz"
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Use wget or curl
    DOWNLOAD_CMD=""
    if command -v wget &>/dev/null; then
        DOWNLOAD_CMD="wget -q"
    elif command -v curl &>/dev/null; then
        DOWNLOAD_CMD="curl -L -o"
    else
        echo "Error: Neither wget nor curl is installed. Cannot download."
        cd - >/dev/null
        rm -rf "$TEMP_DIR"
        echo "Skipping settings app installation."
    fi

    if [ -n "$DOWNLOAD_CMD" ]; then
        echo "Downloading pre-built binary..."
        if $DOWNLOAD_CMD app.tar.gz "$RELEASE_URL"; then
            echo "Extracting..."
            tar -xzf app.tar.gz
            # Look for the binary anywhere under the current directory
            BIN_PATH=$(find . -type f -executable -name "myi3configsettings" | head -n1)
            if [ -n "$BIN_PATH" ]; then
                BIN_DIR="$HOME/.local/bin"
                mkdir -p "$BIN_DIR"
                cp "$BIN_PATH" "$BIN_DIR/"
                chmod +x "$BIN_DIR/myi3configsettings"
                echo "Installed to $BIN_DIR/myi3configsettings"

                # Create desktop entry
                echo "Creating desktop entry..."
                mkdir -p "$HOME/.local/share/applications"
                cat > "$HOME/.local/share/applications/myi3configsettings.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=MyI3ConfigSettings
Comment=Manage i3/sway keybindings, theme, input, and workspaces
Exec=$BIN_DIR/myi3configsettings
Icon=preferences-system
Terminal=false
Categories=Settings;System;
StartupNotify=true
EOF
                echo "Desktop entry created at ~/.local/share/applications/myi3configsettings.desktop"
            else
                echo "Error: Binary not found in extracted archive."
                echo "Falling back to building from source (requires npm and cargo)."
                cd "$REPO_DIR"
                rm -rf "$TEMP_DIR"
                git clone https://github.com/JGH0/MyI3ConfigSettings.git /tmp/MyI3ConfigSettings
                cd /tmp/MyI3ConfigSettings
                if npm install && cargo tauri build; then
                    BINARY_PATH=$(find src-tauri/target/release -maxdepth 1 -type f -executable \( -name "myi3configsettings" -o -name "MyI3ConfigSettings" \) | head -n1)
                    if [ -n "$BINARY_PATH" ]; then
                        BIN_DIR="$HOME/.local/bin"
                        mkdir -p "$BIN_DIR"
                        cp "$BINARY_PATH" "$BIN_DIR/"
                        echo "Built and installed to $BIN_DIR/$(basename "$BINARY_PATH")"
                    else
                        echo "Error: Binary not found after build."
                    fi
                else
                    echo "Build failed. Please install npm and cargo or download the binary manually."
                fi
                cd - >/dev/null
                rm -rf /tmp/MyI3ConfigSettings
            fi
        else
            echo "Failed to download pre-built binary. Falling back to building from source (requires npm and cargo)."
            cd "$REPO_DIR"
            rm -rf "$TEMP_DIR"
            git clone https://github.com/JGH0/MyI3ConfigSettings.git /tmp/MyI3ConfigSettings
            cd /tmp/MyI3ConfigSettings
            if npm install && cargo tauri build; then
                BINARY_PATH=$(find src-tauri/target/release -maxdepth 1 -type f -executable \( -name "myi3configsettings" -o -name "MyI3ConfigSettings" \) | head -n1)
                if [ -n "$BINARY_PATH" ]; then
                    BIN_DIR="$HOME/.local/bin"
                    mkdir -p "$BIN_DIR"
                    cp "$BINARY_PATH" "$BIN_DIR/"
                    echo "Built and installed to $BIN_DIR/$(basename "$BINARY_PATH")"
                else
                    echo "Error: Binary not found after build."
                fi
            else
                echo "Build failed. Please install npm and cargo or download the binary manually."
            fi
            cd - >/dev/null
            rm -rf /tmp/MyI3ConfigSettings
        fi
    fi

    cd - >/dev/null
    rm -rf "$TEMP_DIR"
else
    echo "Skipping settings app installation."
    echo "You can manually install it later from:"
    echo "  https://github.com/JGH0/MyI3ConfigSettings"
fi

# Add ~/.local/bin to PATH if not already (for fish shell)
if [ -f "$HOME/.config/fish/config.fish" ]; then
    if ! grep -q "$HOME/.local/bin" "$HOME/.config/fish/config.fish"; then
        echo "Adding ~/.local/bin to fish PATH..."
        echo "set -gx PATH \$HOME/.local/bin \$PATH" >> "$HOME/.config/fish/config.fish"
    fi
fi

# For bash/zsh
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "$HOME/.local/bin" "$HOME/.bashrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        echo "Added ~/.local/bin to bash PATH (restart shell or source ~/.bashrc)"
    fi
fi

if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "$HOME/.local/bin" "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
        echo "Added ~/.local/bin to zsh PATH (restart shell or source ~/.zshrc)"
    fi
fi

# ----------------------------
# Done
# ----------------------------
echo
echo "✓ Done"
echo
if [ "$WM" = "sway" ]; then
    echo "For Sway, reload with: Super + Shift + C"
else
    echo "For i3, reload with: Super + Shift + C"
fi
echo
echo "The Tauri settings app (if installed) will manage your keybindings, theme, input, and workspaces."
echo "You can launch it with: myi3configsettings"
echo "It should also appear in your application launcher (rofi, dmenu, etc.)"

# Optional: if keybindings.json is corrupted, suggest fix
if grep -q "not found" "$CFG_ROOT/keybindings.json" 2>/dev/null; then
    echo
    echo "Note: Your keybindings.json appears to be corrupted (contains error messages)."
    echo "To fix it, run: cp $CFG_ROOT/default-keybindings.json $CFG_ROOT/keybindings.json"
    echo "Then re-run the installer or manually regenerate the .conf files."
fi