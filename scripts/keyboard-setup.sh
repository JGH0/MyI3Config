#!/bin/bash

if [ -n "$SWAYSOCK" ]; then
    swaymsg input type:keyboard xkb_layout "us,ch"
    swaymsg input type:keyboard xkb_variant "workman,de"
else
    setxkbmap -layout us,ch -variant workman,de
fi