#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CFG_ROOT="$HOME/.config/MyI3Config"
I3_DIR="$HOME/.config/i3"

ask() {
	printf "%s [y/N]: " "$1"
	read -r ans
	[ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

ask_app() {
	local label="$1"
	local default="$2"
	local app

	while true; do
		printf "%s (default: %s): " "$label" "$default"
		read -r app
		app="${app:-$default}"

		if command -v "$app" >/dev/null 2>&1; then
			echo "$app"
			return
		else
			echo "✗ '$app' not found in PATH"
			echo "  install it first or choose another"
		fi
	done
}

echo "=== MyI3Config installer ==="
echo

if ! ask "Install this i3 configuration?"; then
	echo "Aborted."
	exit 0
fi

echo
echo "[1/4] Installing packages"
sudo pacman -S --needed $(grep -v '^#' "$REPO_DIR/packages.txt")

echo
echo "[2/4] Choose applications"
TERMINAL=$(ask_app "Terminal" "kitty")
BROWSER=$(ask_app "Browser" "firefox")
FILEMANAGER=$(ask_app "File manager" "nautilus")
CALCULATOR=$(ask_app "Calculator" "gnome-calculator")

echo
echo "[3/4] Installing MyI3Config"
rm -rf "$CFG_ROOT"
mkdir -p "$CFG_ROOT"
cp -r "$REPO_DIR/"* "$CFG_ROOT"

echo
echo "[4/4] Writing settings"
echo "$TERMINAL"    > "$CFG_ROOT/settings/terminal.sh"
echo "$BROWSER"     > "$CFG_ROOT/settings/browser.sh"
echo "$FILEMANAGER" > "$CFG_ROOT/settings/filemanager.sh"
echo "$CALCULATOR"  > "$CFG_ROOT/settings/calculator.sh"

chmod +x "$CFG_ROOT/i3/"*.sh

echo
echo "Installing i3 config → ~/.config/i3/config"
mkdir -p "$I3_DIR"
cp "$CFG_ROOT/i3/config" "$I3_DIR/config"

echo
echo "✓ Done"
echo
echo "Reload i3 with: Super + Shift + C"