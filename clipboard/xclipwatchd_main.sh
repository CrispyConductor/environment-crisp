#!/bin/bash

LOOP_DELAY=0.5
LOOP_DELAY_BIG=5
BIG_THRESHOLD=50000

TEMPFILE="/tmp/_clip_xcwatchd1_yssh$USER"
TEMPFILE2="/tmp/_clip_xcwatchd2_yssh$USER"
MYDIR="$(realpath "$(dirname "$0")")"

if command -v xclip &>/dev/null; then
	PASTECOMMAND="xclip -o -selection clipboard"
	NEEDENV=1
elif command -v pbcopy &>/dev/null; then
	PASTECOMMAND="pbpaste"
	NEEDENV=0
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

update_clip() {
	fn="$1"

	# make sure new contents do not equal current contents
	"$MYDIR/getcopybuffer.sh" 0 > "$TEMPFILE2"
	cmp "$fn" "$TEMPFILE2" &>/dev/null
	if [ $? -ne 1 ]; then rm -f "$TEMPFILE2"; return; fi
	rm -f "$TEMPFILE2"

	# load new buffer into tmux and notify vims
	tmux load-buffer "$fn"
	"$MYDIR/updatevims.sh"

	# propagate tmux clipboard to other connected machines
	"$MYDIR/clipsyncd_propagate.sh" &>/dev/null
}

# make sure $DISPLAY is set
if [ -z "$DISPLAY" ]; then
	echo no DISPLAY 1>&2
	exit 0
fi

$PASTECOMMAND >"$TEMPFILE" 2>/dev/null
if [ $? -ne 0 ]; then
	echo -n '' > "$TEMPFILE"
fi
LSIZE=`cat "$TEMPFILE" | wc -c`
LHASH="`cat "$TEMPFILE" | md5sum | cut -d ' ' -f 1`"
rm -f "$TEMPFILE"

# keep fetching clipboard until a change is found
# wait longer if last clip was longer
while [ 1 ]; do
	# Check if the flag file exists to call pushtogui
	if [ -f ~/.xclipwatchd_pushbuf ]; then
		"$MYDIR/pushtogui.sh"
		rm -f ~/.xclipwatchd_pushbuf
		sleep $LOOP_DELAY
		continue
	fi
	# Check if X clipboard has changed
	$PASTECOMMAND >"$TEMPFILE" 2>/dev/null
	if [ $? -ne 0 ]; then
		rm -f "$TEMPFILE"
		sleep $LOOP_DELAY_BIG
		continue
	fi
	CHASH="`cat "$TEMPFILE" | md5sum | cut -d ' ' -f 1`"
	if [ "$CHASH" != "$LHASH" ]; then
		# clipboard changed
		LHASH="$CHASH"
		LSIZE=`cat "$TEMPFILE" | wc -c`
		update_clip "$TEMPFILE"
	fi
	rm -f "$TEMPFILE"
	d=$LOOP_DELAY
	if [ $LSIZE -gt $BIG_THRESHOLD ]; then d=$LOOP_DELAY_BIG; fi
	sleep $d
done



