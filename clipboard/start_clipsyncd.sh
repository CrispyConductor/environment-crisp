#!/bin/bash

# Don't run if already running
pcount=`ps ux | grep -v grep | grep clipsyncd_main.sh | wc -l`
if [ $pcount -gt 2 ]; then exit; fi

MYDIR="$(realpath "$(dirname "$0")")"
nohup "$MYDIR/clipsyncd_main.sh" </dev/null >/dev/null 2>&1 &
disown

