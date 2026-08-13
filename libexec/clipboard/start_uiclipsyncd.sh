#!/bin/bash

# Don't run if already running
pcount=`ps ux | grep -v grep | grep uiclipsyncd | wc -l`
if [ $pcount -gt 2 ]; then exit; fi

MYDIR="$(realpath "$(dirname "$0")")"
PYTHON="`which python3`"

X_ENV_FILE="$HOME/.user_env_x.env"
if test -f $X_ENV_FILE; then
	source $X_ENV_FILE
fi


nohup "$PYTHON" "$MYDIR/uiclipsyncd.py" </dev/null >/dev/null 2>&1 &
disown

