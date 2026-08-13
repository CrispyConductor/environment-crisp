# Setup steps for the zsh module.

# Install oh-my-zsh if it is not already there.
#
# Cloned into place rather than run through the upstream install script. The
# installer refuses to touch an existing ~/.oh-my-zsh - which by this point
# already holds our linked theme, since file trees are installed before hooks -
# and it also wants to rewrite ~/.zshrc and run chsh, both of which the old
# setup.sh had to suppress with RUNZSH/CHSH environment variables.

if [ ! -f "$TARGET_HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
	if have_cmd git; then
		info 'installing oh-my-zsh'
		if [ "${DRY_RUN:-0}" = 1 ]; then
			step 'would clone ohmyzsh into ~/.oh-my-zsh'
		else
			_omz_tmp="$(mktemp -d)"
			if git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$_omz_tmp/omz"; then
				mkdir -p "$TARGET_HOME/.oh-my-zsh"
				# Copy contents, keeping anything already installed there.
				cp -a "$_omz_tmp/omz/." "$TARGET_HOME/.oh-my-zsh/"
				good 'installed oh-my-zsh'
			else
				warn 'oh-my-zsh clone failed'
			fi
			rm -rf "$_omz_tmp"
			unset _omz_tmp
		fi
	else
		warn 'git not found; skipping oh-my-zsh'
	fi
else
	verbose 'oh-my-zsh already installed'
fi
