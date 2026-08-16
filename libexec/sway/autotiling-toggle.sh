#!/bin/sh
#
# Toggle autotiling on or off for the focused workspace.
#
# autotiling has no runtime control: its --workspaces list is bound into the
# event handler with functools.partial at startup, and it installs no signal
# handler and no IPC command interface. The only way to change the set of
# autotiled workspaces is to restart the process with a different -w.
#
# So that is what this does. It keeps the workspace list in its own state file,
# edits it, and respawns autotiling. The respawn is cheap - autotiling holds no
# state of its own, it just reacts to the next window event.
#
# Deliberately not using /tmp/autotiling, which autotiling itself writes: that
# path is hardcoded to $TMPDIR/autotiling with no per-instance component, it is
# write-only (autotiling never reads it back), and it exists purely so nwg-panel
# can display status. Any second autotiling process on the machine clobbers it.

set -eu

STATE="${XDG_RUNTIME_DIR:-/tmp}/autotiling-workspaces"

# What the state file seeds to on first run. Empty because this repo starts
# sway with autotiling off entirely - see variables.d/20-autotiling.conf - so
# the first toggle should enable exactly the workspace it is invoked on and
# nothing else. The distro's own default would be "1 3 5 7 9".
DEFAULT_WORKSPACES=""

# Everything after -w in the running instance's command line, so a hand-started
# autotiling with a different list is picked up instead of the seed.
#
# The "sh -c" wrapper sway execs at startup is skipped: it carries the same -w
# text, but matching it would make the pkill below target the wrapper rather
# than the python process doing the work.
running_workspaces() {
	pgrep -af autotiling 2>/dev/null |
		grep -F '/usr/bin/autotiling' |
		head -n1 |
		sed -n 's/.*-w \(.*\)$/\1/p'
}

# Prefer the state file, then whatever is actually running (so an autotiling
# started by hand is adopted rather than silently discarded), then the seed.
if [ -f "$STATE" ]; then
	current=$(cat "$STATE")
else
	current=$(running_workspaces)
	[ -n "$current" ] || current="$DEFAULT_WORKSPACES"
fi

ws=$(swaymsg -t get_workspaces --raw | jq -r '.[] | select(.focused) | .num')
if [ -z "$ws" ] || [ "$ws" = "null" ]; then
	notify-send "Autotiling" "Could not determine the focused workspace"
	exit 1
fi

# Rebuild the list with $ws removed, then decide from whether that changed
# anything whether this was an enable or a disable.
new=""
found=0
for w in $current; do
	if [ "$w" = "$ws" ]; then
		found=1
	else
		new="${new:+$new }$w"
	fi
done

if [ "$found" = 1 ]; then
	state="off"
else
	new="${new:+$new }$ws"
	state="on"
fi

printf '%s' "$new" > "$STATE"

# Kill every autotiling instance, not just one: a stray from an earlier session
# would otherwise keep enforcing the old list and fight the new process.
#
# Deliberately not "pkill -f autotiling". The process name is python3, so the
# match has to be against the command line - and that pattern also matches any
# shell whose own command line happens to mention the path, this script's caller
# included. pkill would then kill the caller. So: resolve candidates, then
# confirm each one really is autotiling by reading argv[1] out of /proc before
# signalling it.
for pid in $(pgrep -f '/usr/bin/autotiling' 2>/dev/null); do
	[ "$pid" = "$$" ] && continue
	# cmdline is NUL-separated; argv[1] is the script python is running.
	argv1=$(tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null | sed -n '2p')
	case "$argv1" in
	*/autotiling) kill "$pid" 2>/dev/null || true ;;
	esac
done

# Nothing left enabled means leave it stopped rather than starting an instance
# with an empty -w, which autotiling reads as "every workspace".
if [ -n "$new" ]; then
	# shellcheck disable=SC2086
	setsid autotiling -w $new >/dev/null 2>&1 &
fi

notify-send "Autotiling ${state}" "Workspace ${ws}\nEnabled on: ${new:-none}"
