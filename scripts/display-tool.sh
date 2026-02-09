#!/bin/bash

if [ -n "$SWAYSOCK" ]; then
    # Sway
    wdisplays
else
    # i3
    arandr
fi