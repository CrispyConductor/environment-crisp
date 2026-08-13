# Setup steps for the macOS module.

if ! have_cmd brew; then
	warn 'Homebrew is not installed; see doc/macos-setup.md'
fi

# node is installed as a formula rather than through fnm on macOS; keep npm's
# global prefix inside $HOME so LSP servers land somewhere writable.
if have_cmd npm; then
	if [ "$(npm config get prefix 2>/dev/null)" != "$TARGET_HOME/.local" ]; then
		info 'pointing npm global prefix at ~/.local'
		run npm set prefix "$TARGET_HOME/.local"
	fi
fi
