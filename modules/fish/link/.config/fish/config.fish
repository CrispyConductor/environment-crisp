# Intentionally almost empty.
#
# Fish sources conf.d/*.fish in alphabetical order and only then this file, so
# anything set here would override conf.d/90-local.fish - the per-machine
# overrides file. Keeping config.fish empty is what lets local overrides
# actually win, and it is also fish's own recommended layout.
#
# Configuration lives in conf.d/:
#
#   10-env.fish          exported environment and $PATH
#   20-interactive.fish  key bindings, cursor, greeting, ls colours
#   30-colors.fish       syntax highlighting and pager colours
#   40-x-env.fish        X / Wayland environment capture for detached sessions
#   50-tools.fish        fnm, bun
#   60-ssh-agent.fish    shared ssh-agent
#   90-local.fish        per-machine settings and overrides (not in the repo)
#
# Functions live in functions/, where fish autoloads each one on first use
# instead of defining them on every shell start.
