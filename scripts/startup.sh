#!/bin/bash

if [ -n "$SWAYSOCK" ]; then
    # Sway startup commands
    # Set cursor (optional, Sway handles this differently)
    # For Sway, output configuration should be in the config file, not here
    echo "Running Sway startup"
else
    # i3 startup commands
    xsetroot -cursor_name left_ptr
    xrandr --output HDMI-1 --auto --left-of DP-2 --output DP-2 --auto
fi