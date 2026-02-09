#!/bin/bash

if [ -n "$SWAYSOCK" ]; then
    # Sway
    swaylock
else
    # i3
    i3lock
fi