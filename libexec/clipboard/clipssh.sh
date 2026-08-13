#!/bin/bash

localbasedir="$HOME/.clipsync"

localid="`cat ~/.clipsync/hostid`"
if [ $? -ne 0 ]; then
	echo 'clipssh: Initialization error - could not get local host id' 1>&2
	exit 1
fi

echo 'clipssh: getting remote host info' 1>&2
remoteinfo="`ssh "$@" 'cat "$HOME/.clipsync/hostid" && echo "$HOME/.clipsync"'`"
if [ $? -ne 0 ]; then
	echo 'clipssh: Initialization error - could not get remote host info' 1>&2
	exit 1
fi

remoteid="`echo "$remoteinfo" | head -n1`"
remotebasedir="`echo "$remoteinfo" | head -n2 | tail -n1`"
echo "clipssh: remoteid=$remoteid remotebasedir=$remotebasedir" 1>&2

sessid="`date +%s`${RANDOM}"

tun_r="${remotebasedir}/sock_in/${localid}+${sessid}:${localbasedir}/clipsync.sock"
tun_l="${localbasedir}/sock_out/${remoteid}+${sessid}:${remotebasedir}/clipsync.sock"

echo "clipssh: ssh -R $tun_r -L $tun_l $@" 1>&2

ssh -R "$tun_r" -L "$tun_l" "$@"

