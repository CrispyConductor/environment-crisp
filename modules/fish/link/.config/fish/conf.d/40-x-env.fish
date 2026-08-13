# Record the graphical session's environment so detached sessions can find it.
#
# A tmux session started from a desktop login keeps working after the login
# shell that spawned it is gone, but things like the GUI clipboard bridge still
# need DISPLAY / WAYLAND_DISPLAY. On login we stash the relevant variables in a
# file that other tools can read.
#
# The filename matters: tmux.conf (@copytk-quickopen-env-file) and
# libexec/clipboard/start_uiclipsyncd.sh both read this exact path. It used to
# differ between them - fish wrote ~/.user_env_x.env while tmux and zsh looked
# for ~/.user_env_x - so the environment never actually loaded.

if status --is-login; or test -z "$X_ENV_FILE"
	set -g X_ENV_FILE $HOME/.user_env_x.env

	if test -n "$WAYLAND_DISPLAY"
		store_env $X_ENV_FILE WAYLAND_DISPLAY
		chmod 600 $X_ENV_FILE
	else if test -n "$DISPLAY"
		store_env $X_ENV_FILE DISPLAY XMODIFIERS XDG_RUNTIME_DIR XDG_SESSION_ID \
			XDG_CURRENT_DESKTOP XDG_SESSION_CLASS XDG_DATA_DIRS XDG_SESSION_DESKTOP \
			XDG_SESSION_TYPE I3SOCK XAUTHORITY XDG_VTNR XDG_CONFIG_DIRS XDG_SEAT
		chmod 600 $X_ENV_FILE
	else if test -f $X_ENV_FILE
		# Deliberately not loaded automatically: pulling a stale DISPLAY into a
		# shell that belongs to a live UI session breaks that session. Run
		# `load_env $X_ENV_FILE` by hand when a detached shell needs it.
	end
end
