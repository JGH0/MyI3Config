#!/bin/bash

# layout-toggle.sh

if [ -n "$SWAYSOCK" ]; then
    swaymsg input type:keyboard xkb_switch_layout next
else
    current=$(setxkbmap -query | awk '/layout/{print $2}')
    if [ "$current" = "ch" ]; then
        setxkbmap -layout us -variant workman
    else
        setxkbmap -layout ch -variant de
    fi
fi