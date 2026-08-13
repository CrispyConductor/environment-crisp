#!/bin/bash
#pgrep -lt $(tmux list-panes -F "#{pane_active} #{pane_tty}" | grep -E "^1" | cut -d " " -f 2- | cut -d / -f 3-) | grep -E "ssh|tmux" &>/dev/null

TTY="`tmux list-panes -F "#{pane_active} #{pane_tty}" | grep -E "^1" | cut -d " " -f 2- | cut -d / -f 3-`"
if [ -z $TTY ]; then exit 1; fi
ps -ao tty,comm | grep -E "^${TTY}\\s" | grep -E "ssh|tmux" &>/dev/null

exit $?

