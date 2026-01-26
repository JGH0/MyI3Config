#!/bin/sh
# Fullscreen overlay menu
OPTIONS="Reboot\nShutdown\nLock Screen\nCancel"
CHOICE=$(echo -e $OPTIONS | rofi -dmenu -fullscreen -p "Action" -lines 4 -bw 2 -kb-accept-entry 'Return' -kb-cancel 'Escape')

case "$CHOICE" in
    "Reboot") systemctl reboot ;;
    "Shutdown") systemctl poweroff ;;
    "Lock Screen") i3lock ;;
    "Cancel"|"") exit 0 ;;
esac

