#!/bin/sh

# Load buffer into tmux
TEMPFILE="`tempfile`"
cat > "$TEMPFILE"
tmux load-buffer "$TEMPFILE"
rm -f "$TEMPFILE"

# Trigger other running vims to pull in update
MYDIR="$(realpath "$(dirname "$0")")"
"$MYDIR/updatevims.sh"



