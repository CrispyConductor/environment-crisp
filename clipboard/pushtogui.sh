#!/bin/bash

if command -v xclip &>/dev/null; then
	COPYCOMMAND="xclip -i -selection clipboard"
	NEEDENV=1
elif command -v pbcopy &>/dev/null; then
	COPYCOMMAND="pbcopy"
	NEEDENV=0
elif command -v xsel &>/dev/null; then
	COPYCOMMAND="xsel"
	NEEDENV=1
else
	echo no copy utility 1>&2
	exit 0
fi

# make sure $DISPLAY is set
if [ -z "$DISPLAY" ] && [ $NEEDENV = '1' ]; then
	echo no DISPLAY 1>&2
	# use backup of storing to temp file and xclipwatchd
	touch ~/.xclipwatchd_pushbuf
	exit 0
fi

MAXSIZE=10000000
MYDIR="$(realpath "$(dirname "$0")")"

TEMPFILE="`tempfile 2>/dev/null`"
if [ $? -ne 0 ]; then
	TEMPFILE="/tmp/_clip_temppshgui_yssh$USER"
fi

"$MYDIR/getcopybuffer.sh" 0 > "$TEMPFILE"
if [ $? -ne 0 ]; then rm -f "$TEMPFILE"; exit 0; fi
if [ -z "`cat "$TEMPFILE"`" ]; then rm -f "$TEMPFILE"; exit 0; fi
if [ `cat "$TEMPFILE" | wc -c` -gt $MAXSIZE ]; then rm -f "$TEMPFILE"; exit 0; fi

$COPYCOMMAND < "$TEMPFILE"
#xclip -i "$TEMPFILE" -selection clipboard

rm -f "$TEMPFILE"

