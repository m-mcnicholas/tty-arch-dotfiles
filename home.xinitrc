#!/bin/sh
# Share the console palette with xterm, i3, and dmenu through X resources.
theme="${XDG_CONFIG_HOME:-$HOME/.config}/theme/${TTY_THEME:-gruvbox}.sh"
if [ -r "$theme" ]; then
  . "$theme"
  {
    i=0
    while [ "$i" -lt 16 ]; do
      eval "printf '*color%d: #%s\n' $i \"\$color$i\""
      i=$((i + 1))
    done
    printf '*background: #%s\n*foreground: #%s\n*cursorColor: #%s\n' "$color0" "$color7" "$color7"
    printf 'XTerm*faceName: monospace\nXTerm*faceSize: 11\nXTerm*internalBorder: 8\n'
  } | xrdb -nocpp -merge -
fi
exec i3
