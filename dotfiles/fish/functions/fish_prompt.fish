
function fish_prompt --description 'Write out the prompt'
	set -l color_cwd
	set -l suffix
	set -l color_suffix normal
	set -l attr_suffix
	set -l color_host "$fish_color_host"
	set -l color_user "$fish_color_user"

	switch "$USER"
		case root toor
			if set -q fish_color_cwd_root
				set color_cwd $fish_color_cwd_root
			else
				set color_cwd $fish_color_cwd
			end
			set suffix '# '
		case '*'
			set color_cwd $fish_color_cwd
			set suffix '$ '
	end

	if test "$fish_key_bindings" = "fish_vi_key_bindings"; or test "$fish_key_bindings" = "fish_hybrid_key_bindings"
		switch $fish_bind_mode
			case default
				set suffix '>>'
				set color_suffix red
			case insert
				# use default
			case replace_one
				set suffix '>>'
				set color_suffix red
				set attr_suffix --bold
			case replace
				set suffix '>>'
				set color_suffix red
				set attr_suffix --bold
			case visual
				set suffix '>>'
				set color_suffix red
				set attr_suffix --bold
		end
	end

	set -l host_max_len 9
	set -l host_prompt_str (prompt_hostname)
	if test (string length $host_prompt_str) -gt $host_max_len
		set host_prompt_str (string sub -l (math $host_max_len - 1) $host_prompt_str)'…'
	end

	echo -n -s (set_color $color_user) "$USER" @ (set_color $color_host) $host_prompt_str (set_color normal) ' ' (set_color $color_cwd) (prompt_pwd) (set_color $attr_suffix $color_suffix) "$suffix" (set_color normal)

end

# Determine hostname color
if test -n "$hostname"
	set -l fishdir (dirname (status filename))/..
	set -l hostnamere '^'(echo $hostname | sed 's/\./\\\\./g')' '
	set -l hcline (grep -i $hostnamere $fishdir/hostname_colors)
	if test $status -eq 0
		# hostname found in hostname_colors file
		set -g fish_color_host (echo $hcline | head -n1 | cut -d ' ' -f 2-)
	else
		# hostname not in colors file, used random file based on cksum
		set -l rcolors (cat $fishdir/hostname_colors_random | grep .)
		set -l ncolor (math (echo $hostname | cksum | cut -d ' ' -f 1) \% (count rcolors) + 1)
		set -g fish_color_host $rcolors[$ncolor]
	end
end

function record_cmd_exit_status_for_prompt -e fish_postexec
	set -l lstatus $status
	if test ! -z ''(string trim "$argv")
		set -g fish_prompt_exit_status $lstatus
	end
end

function fish_right_prompt
	if test ! -z "$fish_prompt_exit_status" -a "$fish_prompt_exit_status" -ne 0
		echo -n -s ' ' (set_color red) '↵' $fish_prompt_exit_status (set_color normal) ' '
		set -g fish_prompt_exit_status 0
	end
end

function fish_mode_prompt
	# empty - handled in main prompt
end

