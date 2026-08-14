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

# Keep npm's global prefix inside $HOME so LSP servers land somewhere
# writable at a fixed path regardless of the active fnm version - init.lua
# looks for them under ~/.local/lib/node_modules. Mirrors modules/macos.
#
# Guarded on the binary actually being present (rather than going through
# run()) because this reads its output, and under --dry-run nothing was
# really installed above for it to query.
if [ -x "$_fnm_bin" ]; then
	_fnm_npm_prefix="$(env HOME="$TARGET_HOME" "$_fnm_bin" exec --using=lts-latest -- npm config get prefix 2>/dev/null)"
	if [ "$_fnm_npm_prefix" != "$TARGET_HOME/.local" ]; then
		info 'pointing npm global prefix at ~/.local'
		run env HOME="$TARGET_HOME" "$_fnm_bin" exec --using=lts-latest -- npm set prefix "$TARGET_HOME/.local"
	fi
	unset _fnm_npm_prefix
fi

unset _fnm_bin
