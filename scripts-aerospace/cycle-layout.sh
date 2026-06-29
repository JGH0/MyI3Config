#!/bin/bash
# macOS keyboard layout toggle
# Mirrors the i3/sway layout switching ($mod+space)
# Toggles between Workman (US) and Swiss German (CH) layouts
#
# Requires: macOS 10.12+ (built-in keyboard input source switching)

CURRENT=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources 2>/dev/null | grep -o '"KeyboardLayout Name" = "[^"]*"' | head -1 | cut -d'"' -f4)

if [ "$CURRENT" = "Workman" ]; then
    # Switch to Swiss German
    "/System/Library/CoreServices/System Events.app/Contents/MacOS/System Events" \
        1>/dev/null 2>/dev/null &
    sleep 0.1
    osascript -e 'tell application "System Events" to key code 103 using {command down, option down}' 2>/dev/null
else
    # Switch to Workman (assuming it's set up as "U.S." with Workman variant)
    "/System/Library/CoreServices/System Events.app/Contents/MacOS/System Events" \
        1>/dev/null 2>/dev/null &
    sleep 0.1
    osascript -e 'tell application "System Events" to key code 103 using {command down, option down}' 2>/dev/null
fi
