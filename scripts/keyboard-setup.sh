#!/bin/bash

#keyboard-setup.sh
#Only needed for i3 / X11

if [ -z "$SWAYSOCK" ]; then
    setxkbmap -layout ch,us -variant de,workman
fi
