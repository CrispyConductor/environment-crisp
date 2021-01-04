#!/bin/bash

MYDIR="$(realpath "$(dirname "$0")")"

# Ping running vims to cause them to pull in a clipboard update
"$MYDIR/updatevims.sh" &>/dev/null

# Push to connected clipsyncd's
"$MYDIR/clipsyncd_propagate.sh" &


exit 0

