#!/bin/bash

# Don't run if already running
pcount=`ps ux | grep -v grep | grep uiclipsyncd | wc -l`
if [ $pcount -gt 2 ]; then exit; fi

MYDIR="$(realpath "$(dirname "$0")")"
PYTHON="`which python3`"

nohup "$PYTHON" "$MYDIR/uiclipsyncd.py" </dev/null >/dev/null 2>&1 &
disown

