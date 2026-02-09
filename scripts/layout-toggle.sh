#!/bin/bash

# Toggle between CH and US layouts
if [ -n "$SWAYSOCK" ]; then
    # Sway: get current layout and toggle
    current=$(swaymsg -t get_inputs | jq -r '.[] | select(.type=="keyboard") | .xkb_active_layout_name' | head -1)
    if [ "$current" = "Swiss" ] || [ "$current" = "ch" ]; then
        swaymsg input "*" xkb_layout "us"
        swaymsg input "*" xkb_variant "workman"
    else
        swaymsg input "*" xkb_layout "ch"
        swaymsg input "*" xkb_variant "de"
    fi
else
    # i3: get current layout and toggle
    current=$(setxkbmap -query | grep layout | awk '{print $2}')
    if [ "$current" = "ch" ]; then
        setxkbmap -layout us -variant workman
    else
        setxkbmap -layout ch -variant de
    fi
fi