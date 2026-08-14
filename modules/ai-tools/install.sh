# Setup steps for the ai-tools module.
#
# aider and llm are both installed via pipx: pipx on Ubuntu comes from the
# ubuntu-common-base module; on other platforms install it yourself first.
# API keys go in the per-machine local files (~/.shellrc-local,
# ~/.config/fish/conf.d/90-local.fish) - see the README's "Per-machine
# settings" section - never in this module.

if have_cmd pipx; then
	if [ ! -x "$TARGET_HOME/.local/bin/aider" ]; then
		info 'installing aider'
		run env HOME="$TARGET_HOME" pipx install aider-install \
			&& run env HOME="$TARGET_HOME" "$TARGET_HOME/.local/bin/aider-install" \
			|| warn 'aider install failed'
	fi

	if [ ! -x "$TARGET_HOME/.local/bin/llm" ]; then
		info 'installing llm'
		run env HOME="$TARGET_HOME" pipx install llm \
			|| warn 'llm install failed'
	fi
else
	warn 'pipx not found; install it first (the ubuntu-common-base module provides it on Ubuntu)'
fi
