#!/bin/bash

if [ -n "$SWAYSOCK" ]; then
    # Sway
    grim -g "$(slurp)" - | wl-copy
else
    # i3
    maim -s | xclip -selection clipboard -t image/png
fi