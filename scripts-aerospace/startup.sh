#!/bin/bash
# macOS startup commands
# Mirrors the startup.sh behavior from the i3/sway setup

# Set keyboard repeat rate (matches i3/sway input config)
# Fast repeat like default-input.json: repeatRate=30, repeatDelay=300
defaults write -g InitialKeyRepeat -int 15      # ~300ms delay (lower = faster)
defaults write -g KeyRepeat -int 2              # ~30ms repeat rate (1=fast, 120=slow)

# Disable press-and-hold for accented characters (enables key repeat)
defaults write -g ApplePressAndHoldEnabled -bool false

# Set cursor to a reasonable size
defaults write -g com.apple.mouse.scaling -float 3.0

# Show hidden files in Finder (optional)
defaults write com.apple.finder AppleShowAllFiles -bool true

echo "macOS startup settings applied"
echo "Note: Some settings (like keyboard repeat) require a logout/restart to take full effect"
