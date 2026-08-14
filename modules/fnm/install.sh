# Setup steps for the fnm module.
#
# Installs fnm (Fast Node Manager) via its official install script, then
# installs and defaults to the current Node.js LTS. Re-running keeps the LTS
# current, the same way `Lazy! sync` keeps neovim plugins current.
#
# Shell integration is already conditional in fish's conf.d/50-tools.fish
# (`type -q fnm`); bash and zsh do not source `fnm env`, same as before fnm
# was a module. macOS installs node via the homebrew formula instead - see
# modules/macos/install.sh - so this module is Linux-only.

_fnm_bin="$TARGET_HOME/.local/share/fnm/fnm"

if [ ! -x "$_fnm_bin" ]; then
	info 'installing fnm'
	run env HOME="$TARGET_HOME" bash -c 'curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell' \
		|| warn 'fnm install failed'
fi

info 'installing current node LTS'
run env HOME="$TARGET_HOME" "$_fnm_bin" install --lts \
	|| warn 'fnm could not install node; is fnm installed?'
run env HOME="$TARGET_HOME" "$_fnm_bin" default lts-latest \
	|| warn 'fnm could not set the default node version'

unset _fnm_bin
