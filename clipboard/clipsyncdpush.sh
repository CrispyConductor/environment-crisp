#!/bin/bash

if [ $# -ne 2 ]; then
	echo 'Args: <socket> <isupwards 0|1>'
	exit 1
fi

NCOPT=""
if [ `uname` != 'Darwin' ]; then
	NCOPT='-N'
fi

(echo -n $2 && cat) | nc -U $NCOPT "$1"


