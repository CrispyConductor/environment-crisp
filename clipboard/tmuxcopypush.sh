#!/bin/sh

MYDIR="$(realpath "$(dirname "$0")")"

# Ping running vims to cause them to pull in a clipboard update
"$MYDIR/updatevims.sh" &>/dev/null
exit 0

