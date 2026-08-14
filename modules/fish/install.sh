# Setup steps for the fish module.

if have_cmd fish; then
	_fish_path="$(command -v fish)"

	if [ "$TARGET_HOME" != "$HOME" ]; then
		verbose 'not changing the login shell (installing into a different home)'
	else
		case "${SHELL:-}" in
			*fish)
				verbose 'fish is already the login shell'
				;;
			*)
				# chsh refuses a shell that is not listed in /etc/shells.
				if grep -qxF "$_fish_path" /etc/shells 2>/dev/null; then
					info "changing login shell to $_fish_path"
					run chsh -s "$_fish_path" \
						|| warn 'chsh failed; change the login shell by hand'
				else
					warn "$_fish_path is missing from /etc/shells; not changing the login shell"
				fi
				;;
		esac
	fi

	unset _fish_path
else
	warn 'fish is not installed; its config was placed but nothing will read it yet'
fi

# --- fisher (fish package manager) -----------------------------------------

if have_cmd fish; then
	_fisher_fn="$TARGET_HOME/.config/fish/functions/fisher.fish"
	if [ ! -f "$_fisher_fn" ]; then
		info 'installing fisher'
		run env HOME="$TARGET_HOME" fish -c \
			'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher' \
			|| warn 'fisher install failed'
	fi
	unset _fisher_fn
fi
