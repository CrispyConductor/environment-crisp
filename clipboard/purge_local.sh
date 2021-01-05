#!/bin/bash

MYDIR="$(realpath "$(dirname "$0")")"
TEMPFILE="/tmp/_clipsync_purge_sentinal$USER"

# Purges clipboard buffers on local system

# Remove tmux buffers (only automatically named ones)
for bufname in `tmux list-buffers -F '#{buffer_name}' | grep '^buffer[0-9]'`; do
	tmux delete-buffer -b "$bufname"
done

# Add a tmux purge sentinal buffer to indicate a purge
echo -n '!!!___PURGED___!!!' > "$TEMPFILE"
tmux load-buffer "$TEMPFILE"
rm -f "$TEMPFILE"

# Notify vims and gui
"$MYDIR/updatevims.sh"
"$MYDIR/pushtogui.sh" &>/dev/null


