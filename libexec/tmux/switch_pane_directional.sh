#!/bin/bash

# Handles a pane switch directional keypress.  Has the following functions:
# If the current tmux pane contains another tmux session or a ssh command, forward the keypress on to the pane.
# If the current tmux pane is running vim, send keys to vim to trigger a window switch.
# Otherwise, do a normal pane switch.

# Arguments are:
# $1 - U|D|L|R
# $2 - Keys pressed (to forward on in the first case above) in tmux format

if [ $# -ne 2 ]; then echo Invalid args; exit 1; fi

VIMPREFIX='M-w'

TTY="`tmux list-panes -F "#{pane_active} #{pane_tty}" | grep -E "^1" | cut -d " " -f 2- | cut -d / -f 3-`"
if [ -z $TTY ]; then exit 1; fi

PROCS="`ps -ao tty,comm | grep -E "^${TTY}\\s" | awk '{print $2}'`"

if echo "$PROCS" | grep -E "ssh|tmux" &>/dev/null; then
	# pane running ssh or tmux
	tmux send-keys $2
elif echo "$PROCS" | grep -E "vim" &>/dev/null; then
	# pane running vim
	tmux send-keys $VIMPREFIX $1
else
	# pane not running anything special
	tmux select-pane -$1
fi



