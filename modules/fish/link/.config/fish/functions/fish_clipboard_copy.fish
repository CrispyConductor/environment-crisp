# Overrides fish's built-in of the same name so the editor's copy binding feeds
# the tmux/GUI/SSH clipboard stack instead of only the local X selection.
# Copied from the fish original and modified.

function fish_clipboard_copy
	set -l cmdline (commandline --current-selection | string collect)
	test -n "$cmdline"; or set cmdline (commandline | string collect)
	printf '%s' $cmdline | clipcopy
end
