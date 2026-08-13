#!/bin/bash

MYDIR="$(realpath "$(dirname "$0")")"

"$MYDIR/purge_local.sh"

"$MYDIR/clipsyncd_propagate.sh"

