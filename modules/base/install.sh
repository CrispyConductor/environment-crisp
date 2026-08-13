# Setup steps for the base module.
#
# Sourced by install.sh, so the helpers from lib/ are available along with
# TARGET_HOME, REPO_DIR and DRY_RUN. Everything here must be safe to re-run.

# --- commands on PATH -----------------------------------------------------
#
# bin/ is symlinked into ~/.local/bin rather than added to $PATH. The old
# arrangement put path_scripts/ on fish's $fish_user_paths only, so these
# commands did not exist in bash or zsh at all.

info 'linking bin/ commands into ~/.local/bin'
run mkdir -p "$TARGET_HOME/.local/bin"
for _src in "$REPO_DIR"/bin/*; do
	[ -f "$_src" ] || continue
	_name="$(basename "$_src")"
	_dest="$TARGET_HOME/.local/bin/$_name"
	if [ -L "$_dest" ] && [ "$(readlink "$_dest")" = "$_src" ]; then
		state_record base link ".local/bin/$_name" "$_src"
		continue
	fi
	run ln -sfn "$_src" "$_dest"
	state_record base link ".local/bin/$_name" "$_src"
	step "linked $(tilde "$_dest")"
done
unset _src _name _dest

# --- bash includes --------------------------------------------------------
# Order matters: the local file is sourced after ours so it can override.

ensure_line "$TARGET_HOME/.bashrc" 'source ~/.bashrc-env'
ensure_line "$TARGET_HOME/.bashrc" 'source ~/.bashrc-local'

# --- clipboard sync state -------------------------------------------------

info 'preparing clipboard sync state'
run env HOME="$TARGET_HOME" "$REPO_DIR/libexec/clipboard/setup.sh"

# --- clean up the previous installer's dead plugin managers ----------------
#
# setup.sh used to install Packer, vim-plug and Vundle alongside lazy.nvim.
# Only lazy is used. The Packer clone in particular landed under pack/*/start,
# so neovim was loading it on every launch for nothing.

for _stale in \
	"$TARGET_HOME/.local/share/nvim/site/pack/packer" \
	"$TARGET_HOME/.local/share/nvim/site/autoload/plug.vim" \
	"$TARGET_HOME/.local/share/nvim/bundle/Vundle.vim"
do
	if [ -e "$_stale" ]; then
		info "removing unused plugin manager $(tilde "$_stale")"
		run rm -rf "$_stale"
	fi
done
unset _stale

# --- tmux plugins ---------------------------------------------------------

if have_cmd git; then
	_tpm="$TARGET_HOME/.tmux/plugins/tpm"
	if [ ! -d "$_tpm" ]; then
		info 'installing tmux plugin manager'
		run mkdir -p "$TARGET_HOME/.tmux/plugins"
		run git clone --depth 1 https://github.com/tmux-plugins/tpm "$_tpm"
	fi
	# Replaces the manual "in tmux, press Ctrl-b I" step from the old notes.
	#
	# tpm needs a running tmux server to talk to, and by default it would use
	# whichever one the user already has - reading that server's loaded config
	# rather than the one we just installed, and putting our plugin install in
	# the middle of a live session.
	#
	# So we run it against a private server on its own socket (-L), which is
	# created and destroyed here and shares nothing with the default socket.
	# Every tmux call below is pinned to that socket name.
	if have_cmd tmux && [ -x "$_tpm/scripts/install_plugins.sh" ]; then
		info 'installing tmux plugins'
		if [ "${DRY_RUN:-0}" = 1 ]; then
			step 'would install tmux plugins'
		else
			_tmux_sock='userenv-install'
			if env HOME="$TARGET_HOME" tmux -L "$_tmux_sock" \
					-f "$TARGET_HOME/.tmux.conf" new-session -d 2>/dev/null; then
				env HOME="$TARGET_HOME" tmux -L "$_tmux_sock" \
					run-shell "$_tpm/scripts/install_plugins.sh" \
					|| warn 'tmux plugin install failed; run <prefix> I inside tmux'
				env HOME="$TARGET_HOME" tmux -L "$_tmux_sock" kill-server 2>/dev/null || true
			else
				warn 'could not start a temporary tmux server; run <prefix> I inside tmux'
			fi
			unset _tmux_sock
		fi
	fi
	unset _tpm
fi

# --- fzf ------------------------------------------------------------------

if have_cmd git && [ ! -d "$TARGET_HOME/.fzf" ]; then
	info 'installing fzf'
	run git clone --depth 1 https://github.com/junegunn/fzf.git "$TARGET_HOME/.fzf"
	run env HOME="$TARGET_HOME" "$TARGET_HOME/.fzf/install" \
		--key-bindings --completion --no-update-rc
fi

# --- pynvim ---------------------------------------------------------------
# Some neovim plugins need it. On Ubuntu the python3-pynvim package (installed
# by the ubuntu-base module) is the right source; pip is only a fallback, and
# will refuse on PEP 668 systems.

if have_cmd python3 && ! python3 -c 'import pynvim' >/dev/null 2>&1; then
	info 'installing pynvim'
	run python3 -m pip install --user pynvim \
		|| warn 'pynvim install failed; install the python3-pynvim package instead'
fi

# --- neovim plugins -------------------------------------------------------

if have_cmd nvim; then
	info 'syncing neovim plugins'
	run env HOME="$TARGET_HOME" nvim --headless '+Lazy! sync' +qa \
		|| warn 'neovim plugin sync failed'
fi
