
set -gx EDITOR nvim
set -gx USERENVDIR $HOME/.userenv

set -gx STEAM_LIBRARY $HOME/.local/share/Steam/steamapps/

# (more-or-less) consistent ls colors for different versions of ls
set -gx LSCOLORS 'ExGxFxDaCxDaDahbafacec'
set -gx LS_COLORS 'rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=00;36:*.au=00;36:*.flac=00;36:*.m4a=00;36:*.mid=00;36:*.midi=00;36:*.mka=00;36:*.mp3=00;36:*.mpc=00;36:*.ogg=00;36:*.ra=00;36:*.wav=00;36:*.oga=00;36:*.opus=00;36:*.spx=00;36:*.xspf=00;36:' # from dircolors -b

# Override fish's built-in ls function.
# This is based on the built-in function and modified.
for opt in --color=auto -G --color -F
	if command ls $opt / >/dev/null 2>/dev/null
		function ls --description "List contents of directory" -V opt
			command ls $opt $argv
		end
		break
	end
end

# PATH
set -g fish_user_paths $HOME/.local/bin $HOME/bin $HOME/.fzf/bin fish_user_paths

function clipssh
	$USERENVDIR/clipboard/clipssh.sh $argv
end
function clippurge
	$USERENVDIR/clipboard/purge.sh
end
function pushclip
	$USERENVDIR/clipboard/pushclip.sh
end
function getclip
	$USERENVDIR/clipboard/getcopybuffer.sh $argv
end
function clipcopy
	set -l temp
	if type -q mktemp
		set temp (mktemp)
	else if test -d /tmp
		set temp /tmp/fish_clipcopy_$USER
	else
		set temp $HOME/fish_clipcopy
	end
	cat >$temp
	if test (cat $temp | wc -l) -le 1
		echo -n (cat $temp) | $USERENVDIR/clipboard/pushclip.sh
	else
		cat $temp | $USERENVDIR/clipboard/pushclip.sh
	end
	rm -f $temp
end
function clippaste
	$USERENVDIR/clipboard/getcopybuffer.sh
end
function clippurge
	$USERENVDIR/clipboard/purge.sh
end
# These functions are copied and modified from the fish provided ones
function fish_clipboard_copy
	set -l cmdline (commandline --current-selection | string collect)
	test -n "$cmdline"; or set cmdline (commandline | string collect)
	printf '%s' $cmdline | clipcopy
end
function fish_clipboard_paste
	set -l data (clippaste 2>/dev/null)

	# Issue 6254: Handle zero-length clipboard content
	if not string match -qr . -- "$data"
		return 1
	end

	# Also split on \r to turn it into a newline,
	# otherwise the output looks really confusing.
	set data (string split \r -- $data)

	# If the current token has an unmatched single-quote,
	# escape all single-quotes (and backslashes) in the paste,
	# in order to turn it into a single literal token.
	#
	# This eases pasting non-code (e.g. markdown or git commitishes).
	if __fish_commandline_is_singlequoted
		if status test-feature regex-easyesc
			set data (string replace -ra "(['\\\])" '\\\\$1' -- $data)
		else
			set data (string replace -ra "(['\\\])" '\\\\\\\$1' -- $data)
		end
	end
	if not string length -q -- (commandline -c)
		# If we're at the beginning of the first line, trim whitespace from the start,
		# so we don't trigger ignoring history.
		set data[1] (string trim -l -- $data[1])
	end

	if test -n "$data"
		commandline -i -- $data
	end
end

fzf_key_bindings

if status --is-login; or test -z "$X_ENV_FILE"
	set -g X_ENV_FILE $HOME/.user_env_x.fish
	if test ! -z "$DISPLAY"
		env | grep -E '^(X|DISPLAY|I3)' | sed 's/^/set -xg /' | sed 's/=/ \'/' | sed 's/$/\'/' > $X_ENV_FILE
		chmod 600 $X_ENV_FILE
	else if test -z "$DISPLAY" -a -f $X_ENV_FILE
		source $X_ENV_FILE
	end
end

fish_ssh_agent

if test -f ~/.config/fish/config-local.fish
	source ~/.config/fish/config-local.fish
end

