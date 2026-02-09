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

    while true; do
        read -rp "$label (default: $default): " app
        app="${app:-$default}"

        # check if command exists
        if command -v "${app%% *}" >/dev/null 2>&1; then
            echo "$app"
            return
        else
            echo "✗ '$app' not found in PATH"
            echo "  install it first or choose another"
        fi
    done
}

# Detect if running in Sway
is_sway() {
    [ -n "$SWAYSOCK" ] || pgrep -x sway >/dev/null 2>&1
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

# ----------------------------
# 1/4: Install packages
# ----------------------------
echo
echo "[1/4] Installing packages..."

# Initialize package list
PACKAGES=""

# Check for split package files
if [ -f "$REPO_DIR/packages-common.txt" ]; then
    # We have split package configuration
    echo "  Using split package configuration"

    # Always install common packages
    COMMON_PACKAGES=$(grep -v '^#' "$REPO_DIR/packages-common.txt" | tr '\n' ' ')
    PACKAGES="$PACKAGES $COMMON_PACKAGES"

    # Install WM-specific packages
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
    # Fall back to original unified packages.txt
    echo "  Using unified packages.txt"
    PACKAGES=$(grep -v '^#' "$REPO_DIR/packages.txt" | tr '\n' ' ')
fi

# Remove any duplicate packages
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
# 3/4: Install config files
# ----------------------------
echo
echo "[3/4] Installing MyI3Config..."
rm -rf "$CFG_ROOT"
mkdir -p "$CFG_ROOT"
cp -r "$REPO_DIR/"* "$CFG_ROOT"

# ----------------------------
# 4/4: Write settings
# ----------------------------
echo
echo "[4/4] Writing settings..."
echo "$TERMINAL"    > "$CFG_ROOT/settings/terminal.sh"
echo "$BROWSER"     > "$CFG_ROOT/settings/browser.sh"
echo "$FILEMANAGER" > "$CFG_ROOT/settings/filemanager.sh"
echo "$CALCULATOR"  > "$CFG_ROOT/settings/calculator.sh"

# Make all .sh scripts executable
find "$CFG_ROOT/settings" -type f -name "*.sh" -exec chmod +x {} \;

# ----------------------------
# Create symlink for config
# ----------------------------
echo
echo "Linking config..."

if [ "$WM" = "sway" ]; then
    # Link for Sway
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
    # Link for i3
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