# Setup steps for the devtools module.
#
# Installs the language servers init.lua wires up, via whatever npm is
# already on $PATH - this module does not install node itself. On Linux
# that's the fnm module; on macOS it's the node homebrew formula. List this
# module after whichever of those provides npm, so its hook runs later.
#
# @vue/language-server and @vue/typescript-plugin must stay the same version,
# which installing them together in one command keeps true. Re-running keeps
# all of these current, the same way the fnm and rust modules do.

if have_cmd npm; then
	info 'installing language servers'
	run env HOME="$TARGET_HOME" npm install -g pyright \
		|| warn 'pyright install failed'
	run env HOME="$TARGET_HOME" npm install -g typescript typescript-language-server \
		|| warn 'typescript-language-server install failed'
	run env HOME="$TARGET_HOME" npm install -g @vue/language-server @vue/typescript-plugin \
		|| warn 'vue language server install failed'
else
	warn 'npm not found; install node first (the fnm module on Linux, homebrew on macOS)'
fi
