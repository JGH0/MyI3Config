#!/bin/sh
# Toggle between Swiss German (CH_DE) and US Workman layouts
CURRENT=$(setxkbmap -query | grep layout | awk '{print $2}')
if [ "$CURRENT" = "ch" ]; then
    setxkbmap -layout us -variant workman
else
    setxkbmap -layout ch -variant de
fi

