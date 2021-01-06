#!/bin/bash

BASEDIR="$HOME/.clipsync"
INBOUND="$BASEDIR/sock_in"
OUTBOUND="$BASEDIR/sock_out"
HOSTFILE="$BASEDIR/hostid"

mkdir -p "$BASEDIR"
mkdir -p "$INBOUND"
mkdir -p "$OUTBOUND"
chmod 700 "$BASEDIR"

# uncomment to remove old sockets - will disrupt running clipsyncd
#rm -f "$BASEDIR/clipsync.sock"
#rm -f "$INBOUND/*"
#rm -f "$OUTBOUND/*"

if [ ! -f "$HOSTFILE" ]; then
	HOSTID="`hostname -f | sed 's/[^a-zA-Z0-9]/_/g'`_${RANDOM}"
	if [[ "`echo -n "$HOSTID" | wc -c`" -gt 14 ]]; then
		HOSTID="`echo "$HOSTID" | head -c8``echo "$HOSTID" | md5sum | head -c6`"
	fi
	echo $HOSTID > "$HOSTFILE"
fi

