#!/bin/sh

# Load buffer into tmux
TEMPFILE="`tempfile 2>/dev/null`"
if [ $? -ne 0 ]; then
	TEMPFILE="/tmp/_clip_temp_yssh$USER"
fi
cat > "$TEMPFILE"
tmux load-buffer "$TEMPFILE"
rm -f "$TEMPFILE"

# Trigger other running vims to pull in update
MYDIR="$(realpath "$(dirname "$0")")"
"$MYDIR/updatevims.sh"

# Push to connected clipsyncd's
"$MYDIR/clipsyncd_propagate.sh"

