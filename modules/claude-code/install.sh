# Setup steps for the claude-code module.
#
# Installs the Claude Code CLI via Anthropic's native installer (no Node.js
# required) and updates it in place on re-run. Auth is deliberately left out
# of this repo: `claude login` writes ~/.claude/.credentials.json itself, and
# an API key belongs in the per-machine local files instead (see the README's
# "Per-machine settings" section) - never in the linked settings.json.

_claude_bin="$TARGET_HOME/.local/bin/claude"

if [ ! -e "$_claude_bin" ]; then
	info 'installing claude code'
	run env HOME="$TARGET_HOME" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
else
	info 'updating claude code'
	run env HOME="$TARGET_HOME" "$_claude_bin" update
fi

unset _claude_bin
