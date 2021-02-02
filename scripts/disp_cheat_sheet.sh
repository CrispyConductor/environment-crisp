#!/bin/bash

MYDIR="$(realpath "$(dirname "$0")")"
CHEATSHEET="`realpath "$MYDIR/../cheat-sheet.txt"`"
VIMCMD='nvim -M -c "normal zM" "'"$CHEATSHEET"'"'

#cwinid="`tmux list-windows -F '#{window_active} #{window_id}' | grep '^1' | cut -d ' ' -f 2- | head -n1`"
#if [[ -z "$cwinid" ]]; then exit 1; fi
tmux new-window -n 'cheatsheet' "$VIMCMD"

