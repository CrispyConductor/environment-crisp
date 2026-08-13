#!/bin/bash

# Reads clipboard data on stdin and pushes to everything.
# Does some processing in background.

# Load buffer into tmux
MYDIR="$(realpath "$(dirname "$0")")"
TEMPFILE="`tempfile 2>/dev/null`"
if [ $? -ne 0 ]; then
	TEMPFILE="/tmp/_clip_temp_yssh$USER"
fi
export TEMPFILE
export MYDIR
cat > "$TEMPFILE"

(

tmux load-buffer "$TEMPFILE" &>/dev/null
if [ $? -ne 0 ]; then exit 1; fi

# Trigger running vims to pull in update
"$MYDIR/updatevims.sh"

rm -f "$TEMPFILE"

# Push to connected clipsyncd's
"$MYDIR/clipsyncd_propagate.sh"

# Push to gui
"$MYDIR/pushtogui.sh" &>/dev/null

) &

