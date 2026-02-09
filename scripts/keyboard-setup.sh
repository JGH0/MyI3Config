#!/bin/bash

if [ -n "$SWAYSOCK" ]; then
    # Sway
    swaymsg input "*" xkb_layout "ch"
    swaymsg input "*" xkb_variant "de"
else
    # i3
    setxkbmap -layout ch -variant de
fi