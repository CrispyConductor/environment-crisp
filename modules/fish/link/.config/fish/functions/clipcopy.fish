function clipcopy --description 'Read text on stdin and copy it to the clipboard'
	set -l temp
	if type -q mktemp
		set temp (mktemp)
	else if test -d /tmp
		set temp /tmp/fish_clipcopy_$USER
	else
		set temp $HOME/fish_clipcopy
	end
	cat >$temp
	# Single-line input is pushed without its trailing newline, so pasting it
	# into a shell does not immediately execute.
	if test (cat $temp | wc -l) -le 1
		echo -n (cat $temp) | $USERENVDIR/libexec/clipboard/pushclip.sh
	else
		cat $temp | $USERENVDIR/libexec/clipboard/pushclip.sh
	end
	rm -f $temp
end
