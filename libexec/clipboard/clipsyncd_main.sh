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
	srchost="$2"

	# make sure new contents do not equal current contents
	"$MYDIR/getcopybuffer.sh" 0 > "$TEMPFILE"
	S=$?
	if [ $S -ne 0 ] && [ $S -ne 1 ]; then echo 'getcopybuffer.sh error'; return; fi
	cmp "$fn" "$TEMPFILE" &>/dev/null
	if [ $? -ne 1 ]; then return; fi

	if [ "`cat "$fn"`" = '!!!___PURGED___!!!' ]; then
		# local purge
		"$MYDIR/purge_local.sh"
	else
		# load new buffer into tmux and notify vims
		tmux load-buffer "$fn"
		"$MYDIR/updatevims.sh" &

		# push to gui
		"$MYDIR/pushtogui.sh" &>/dev/null &
	fi

	# propagate tmux clipboard to other connected machines, excluding the source
	"$MYDIR/clipsyncd_propagate.sh" "$srchost" &

}

while [ 1 ]; do
	rm -f "$BASEDIR/clipsync.sock"
	nc -l -U "$BASEDIR/clipsync.sock" > "$TEMPFILE"
	if [ $? -eq 0 ]; then
		srchost="`head -n1 "$TEMPFILE"`"
		bskip="`echo "$srchost" | wc -c`"
		tail -c +`expr $bskip + 1` "$TEMPFILE" > "$TEMPFILE2"
		handle_buf "$TEMPFILE2" "$srchost"
	fi
	rm -f "$TEMPFILE" "$TEMPFILE2"
done

