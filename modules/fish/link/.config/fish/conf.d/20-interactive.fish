# Interactive shell behaviour: key bindings, cursor, greeting, ls.
#
# These were universal variables in fish_variables. They are plain globals now
# so they live in the repo instead of in a file fish rewrites behind our back.

set -g fish_key_bindings fish_vi_key_bindings

set -g fish_cursor_default block
set -g fish_cursor_insert block

# Empty value disables the startup greeting.
set -g fish_greeting

# Override fish's built-in ls wrapper with one that picks whichever colour flag
# this system's ls understands. Based on the built-in and modified.
#
# Probing ls costs a couple of exec calls, so only bother for interactive
# shells. Note this must not use `exit` to bail out early: conf.d files are
# sourced by fish itself, and `exit` there would end the shell.
if status is-interactive
	for opt in --color=auto -G --color -F
		if command ls $opt / >/dev/null 2>/dev/null
			function ls --description "List contents of directory" -V opt
				command ls $opt $argv
			end
			break
		end
	end
end
