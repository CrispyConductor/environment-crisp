#!/bin/bash

# Load buffer into tmux
TEMPFILE="`tempfile 2>/dev/null`"
MYDIR="$(realpath "$(dirname "$0")")"
if [ $? -ne 0 ]; then
	TEMPFILE="/tmp/_clip_temp_yssh$USER"
fi
export TEMPFILE
export MYDIR
cat > "$TEMPFILE"

(

tmux load-buffer "$TEMPFILE"

# Trigger other running vims to pull in update
"$MYDIR/updatevims.sh"

rm -f "$TEMPFILE"

# Push to connected clipsyncd's
"$MYDIR/clipsyncd_propagate.sh"

) &

