#!/usr/bin/env bash
set -e

# ----------------------------
# MyI3Config Installer
# ----------------------------

# Detect repository directory dynamically
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG_ROOT="$HOME/.config/MyI3Config"
I3_DIR="$HOME/.config/i3"

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

# ----------------------------
# Installer
# ----------------------------

echo "=== MyI3Config installer ==="
echo

if ! ask "Install this i3 configuration?"; then
    echo "Aborted."
    exit 0
fi

mkdir -p "$HOME/.config"
mkdir -p "$I3_DIR"

# ----------------------------
# 1/4: Install packages
# ----------------------------
echo
echo "[1/4] Installing packages..."
# Remove any packages that don't exist on Arch
PACKAGES=$(grep -v '^#' "$REPO_DIR/packages.txt" | tr '\n' ' ')
sudo pacman -S --needed $PACKAGES || true

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
# Copy i3 config to ~/.config/i3/config
# ----------------------------
echo
echo "Installing i3 config → ~/.config/i3/config"
mkdir -p "$I3_DIR"

if [ -f "$CFG_ROOT/i3/config" ]; then
    cp "$CFG_ROOT/i3/config" "$I3_DIR/config"
else
    echo "Error: i3 config file not found in $CFG_ROOT/i3/"
    exit 1
fi

# ----------------------------
# Done
# ----------------------------
echo
echo "✓ Done"
echo
echo "Reload i3 with: Super + Shift + C"