#!/bin/bash

# Don't run if already running
pcount=`ps ux | grep -v grep | grep clipsyncd_main.sh | wc -l`
if [ $pcount -gt 2 ]; then exit; fi

BASEDIR="$HOME/.clipsync"
mkdir -p "$BASEDIR"
MYDIR="$(realpath "$(dirname "$0")")"

TEMPFILE="/tmp/_clipsyncd_temp_yssh$USER"
TEMPFILE2="/tmp/_clipsyncd_temp2_yssh$USER"

handle_buf() {
	fn="$1"
	isupwards="$2"

	# make sure new contents do not equal current contents
	"$MYDIR/getcopybuffer.sh" 0 > "$TEMPFILE"
	if [ $? -ne 0 ]; then return; fi
	cmp "$fn" "$TEMPFILE" &>/dev/null
	if [ $? -ne 1 ]; then return; fi

	# load new buffer into tmux and notify vims
	tmux load-buffer "$fn"
	"$MYDIR/updatevims.sh"
}

# HMMMM the simple upwards flag may not be enough (may want to propagate to other hosts in the network in the other direction); may just need to ensure it is not sent back to where it originated

while [ 1 ]; do
	rm -f "$BASEDIR/clipsync.sock"
	nc -l -U "$BASEDIR/clipsync.sock" > "$TEMPFILE" 2>/dev/null
	if [ $? -eq 0 ]; then
		isupwards="`head -c1 "$TEMPFILE"`"
		tail -c +2 "$TEMPFILE" > "$TEMPFILE2"
		handle_buf "$TEMPFILE2" $isupwards
	fi
done

