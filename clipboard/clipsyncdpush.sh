#!/bin/bash

if [ $# -ne 1 ]; then
	echo 'Args: <socket>'
	exit 1
fi

localid="`cat ~/.clipsync/hostid`"

NCOPT=""
if [ `uname` != 'Darwin' ]; then
	NCOPT='-N'
fi

(echo "$localid" && cat) | nc -U $NCOPT "$1"
exit $?

