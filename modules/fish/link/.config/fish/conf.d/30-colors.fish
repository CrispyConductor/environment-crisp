# Syntax highlighting, pager and prompt colours.
#
# These used to be universal variables in dotfiles/fish/fish_variables, which
# was symlinked into the repo. That was a hazard: fish owns that file and
# rewrites it by renaming a temp file over the path, which replaces the symlink
# with a regular file and silently detaches the repo copy. Any `set -U`, or a
# fish upgrade bumping __fish_initialized, was enough to trigger it.
#
# As plain globals they are version-controlled, diffable, and fish never
# touches them.

set -g fish_color_autosuggestion 969896
set -g fish_color_cancel red
set -g fish_color_command ff87d7
set -g fish_color_comment e7c547
set -g fish_color_cwd blue
set -g fish_color_cwd_root red
set -g fish_color_end 00ff00
set -g fish_color_error d54e53
set -g fish_color_escape 00a6b2
set -g fish_color_history_current normal
set -g fish_color_host magenta
set -g fish_color_host_remote magenta
set -g fish_color_match e7c547
set -g fish_color_normal normal
set -g fish_color_operator 00a6b2
set -g fish_color_param normal
set -g fish_color_quote normal
set -g fish_color_redirection 87ffff
set -g fish_color_search_match ffff00
set -g fish_color_selection c0c0c0
set -g fish_color_status red
set -g fish_color_user magenta
set -g fish_color_valid_path normal

set -g fish_pager_color_completion normal
set -g fish_pager_color_description B3A06D yellow
set -g fish_pager_color_prefix white --bold --underline
set -g fish_pager_color_progress brwhite --background=cyan
set -g fish_pager_color_selected_background -r

# Per-host prompt colour, so sessions on different machines are easy to tell
# apart. hostname_colors holds explicit choices; anything not listed there gets
# a stable arbitrary colour picked from hostname_colors_random by checksum.
if test -n "$hostname"
	set -l hostnamere '^'(string escape --style=regex -- $hostname)' '
	set -l hcline (grep -iE $hostnamere $__fish_config_dir/hostname_colors)
	if test $status -eq 0
		set -g fish_color_host (echo $hcline | head -n1 | cut -d ' ' -f 2-)
	else
		set -l rcolors (grep . $__fish_config_dir/hostname_colors_random)
		# Note the $ on rcolors: this previously read `count rcolors`, which
		# counted the literal word and always returned 1, so every unlisted
		# host ended up with the same colour.
		set -l ncolor (math (echo $hostname | cksum | cut -d ' ' -f 1) % (count $rcolors) + 1)
		set -g fish_color_host $rcolors[$ncolor]
	end
end
