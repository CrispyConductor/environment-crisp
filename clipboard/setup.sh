#!/bin/bash

BASEDIR="$HOME/.clipsync"
INBOUND="$BASEDIR/sock_in"
OUTBOUND="$BASEDIR/sock_out"
HOSTFILE="$BASEDIR/hostid"

mkdir -p "$BASEDIR"
mkdir -p "$INBOUND"
mkdir -p "$OUTBOUND"

rm -f "$BASEDIR/clipsync.sock"
rm -f "$INBOUND/*"
rm -f "$OUTBOUND/*"

if [ ! -f "$HOSTFILE" ]; then
	HOSTID="`hostname -f | sed 's/[^a-zA-Z0-9]/_/g'`_${RANDOM}${RANDOM}"
	echo $HOSTID > "$HOSTFILE"
fi

