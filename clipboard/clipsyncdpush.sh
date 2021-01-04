#!/bin/sh

if [ $# -ne 2 ]; then
	echo 'Args: <socket> <isupwards 0|1>'
	exit 1
fi

(echo -n $2 && cat) | nc -U -N "$1"


