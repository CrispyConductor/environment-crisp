#!/bin/sh
#
# Rebuild the focused workspace's layout from scratch.
#
#   flatten  (default)  every window becomes a direct child of the workspace
#   retile              flatten, then feed the windows back one at a time so
#                       autotiling rebuilds its spiral over them
#
# Why this is needed: sway has no "flatten" command. `split none` only dissolves
# a container that has exactly one child, and nothing collapses a container when
# a sibling closes - so nesting accumulates and never unwinds on its own.
#
# The trick is that sway garbage-collects a container as soon as its last child
# leaves. Moving every *view* off the workspace therefore dissolves the whole
# container tree, and moving the views back lands them as flat siblings.
#
# Criteria selection is what makes this a two-liner: [workspace="N"] matches
# views only, never the containers holding them, so one command relocates every
# window and takes the scaffolding with it.
#
# The scratch workspace is numbered absurdly high and is never focused, so it
# does not appear in waybar or disturb what is on screen; sway destroys it when
# the last window leaves.

set -eu

MODE="${1:-flatten}"
SCRATCH=99999

ws=$(swaymsg -t get_workspaces --raw | jq -r '.[] | select(.focused) | .name')
if [ -z "$ws" ] || [ "$ws" = "null" ]; then
	notify-send "Retile" "Could not determine the focused workspace"
	exit 1
fi

# Collect the views before moving anything: after the move they are on another
# workspace and the original selection is no longer expressible.
ids=$(swaymsg -t get_tree --raw | jq -r --arg ws "$ws" '
	[ recurse(.nodes[]?, .floating_nodes[]?)
	  | select(.type == "workspace" and .name == $ws) ]
	| first
	| [ recurse(.nodes[]?, .floating_nodes[]?)
	    | select(.pid != null) | .id ]
	| .[]')

if [ -z "$ids" ]; then
	notify-send "Retile" "Workspace ${ws} has no windows"
	exit 0
fi

focused=$(swaymsg -t get_tree --raw | jq -r '
	[ recurse(.nodes[]?, .floating_nodes[]?)
	  | select(.focused == true and .pid != null) ] | first | .id // empty')

# Park everything. This dissolves every container on the workspace.
swaymsg -q "[workspace=\"$ws\"] move container to workspace $SCRATCH"

case "$MODE" in
flatten)
	# Straight back, in one go: they arrive as flat siblings.
	swaymsg -q "[workspace=\"$SCRATCH\"] move container to workspace $ws"
	# If autotiling covers this workspace it re-wraps the focused window the
	# moment focus is restored below, so the result is flat except for one
	# single-child container. Say so rather than looking broken.
	if [ -f "${XDG_RUNTIME_DIR:-/tmp}/autotiling-workspaces" ] &&
		grep -qw "$ws" "${XDG_RUNTIME_DIR:-/tmp}/autotiling-workspaces" 2>/dev/null; then
		notify-send "Flatten" \
			"Workspace ${ws} flattened, but autotiling is enabled here and will re-split as you go. Toggle it off first for a lasting flat layout."
	fi
	;;
retile)
	# One at a time, so autotiling sees a settled geometry per window and splits
	# against it. A bulk move does not work: autotiling keys off the *focused*
	# container, and one move event carrying every window only ever presents it
	# with whatever happened to be focused.
	#
	# The focus and the move have to be a single swaymsg command, in that order.
	# autotiling subscribes to WINDOW events, move included, and each handler run
	# re-reads find_focused(). Move first and the move event is handled while the
	# *previous* window is still focused - a window whose geometry just changed
	# because a sibling left - so autotiling splits that one too and every view
	# ends up double-wrapped in redundant single-child containers. Focusing the
	# window being moved first means both events resolve to it, which is exactly
	# what happens when a window is opened normally.
	for id in $ids; do
		swaymsg -q "[con_id=$id] focus; [con_id=$id] move container to workspace $ws"
		swaymsg -q "workspace $ws"
		# Let autotiling issue its split before the next window changes the
		# geometry out from under it.
		sleep 0.35
	done
	;;
*)
	echo "usage: ${0##*/} [flatten|retile]" >&2
	exit 2
	;;
esac

swaymsg -q "workspace $ws"
[ -n "$focused" ] && swaymsg -q "[con_id=$focused] focus" || true
