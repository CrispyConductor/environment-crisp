# Setup steps for the rust module.
#
# Installs rust via rustup, then the rust-analyzer component for the neovim
# LSP. --no-modify-path because this repo manages $PATH itself (see
# ~/.cargo/bin in fish's conf.d/10-env.fish); rustup's default is to append a
# source line to shell rc files, which we don't want it doing.

_rustup_bin="$TARGET_HOME/.cargo/bin/rustup"

if [ ! -x "$_rustup_bin" ]; then
	info 'installing rust'
	run env HOME="$TARGET_HOME" bash -c \
		'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path' \
		|| warn 'rust install failed'
fi

if [ -x "$_rustup_bin" ]; then
	info 'installing rust-analyzer'
	run env HOME="$TARGET_HOME" "$_rustup_bin" component add rust-analyzer \
		|| warn 'rust-analyzer install failed'
fi

unset _rustup_bin
