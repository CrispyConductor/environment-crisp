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
	# One at a time, applying the split rule to each window as it lands so the
	# next one nests inside it. A bulk move cannot work: the rule depends on the
	# geometry each window has at the moment it arrives.
	#
	# The split is computed here rather than left to autotiling. Relying on the
	# daemon would make this binding do nothing whenever autotiling is disabled
	# for the workspace - which, since this repo ships it off by default, is the
	# normal case - and retile would silently degrade to a slow flatten.
	#
	# The rule is autotiling's own, from its main.py:
	#
	#     new_layout = "splitv" if con.rect.height > con.rect.width else "splith"
	#     if new_layout != con.parent.layout: <issue it>
	#
	# Applying it identically means a *running* autotiling agrees with what we
	# just did and its own check short-circuits, so the two do not fight and no
	# redundant single-child containers appear.
	#
	# The focus and the move are a single swaymsg command, in that order. A
	# running autotiling handles the move event by re-reading find_focused();
	# move first and that resolves to the *previous* window, whose geometry just
	# changed because a sibling left, so it splits that one too and every view
	# ends up double-wrapped. Focusing first makes both events resolve to the
	# window being moved, which is what happens when a window opens normally.
	for id in $ids; do
		swaymsg -q "[con_id=$id] focus; [con_id=$id] move container to workspace $ws"
		swaymsg -q "workspace $ws"

		# Parent's layout plus this window's rect, now that it has been placed.
		set -- $(swaymsg -t get_tree --raw | jq -r --argjson id "$id" '
			[ recurse(.nodes[]?, .floating_nodes[]?)
			  | select( [ (.nodes[]?, .floating_nodes[]?) | .id ] | index($id) ) ]
			| first
			| .layout as $l
			| [ (.nodes[]?, .floating_nodes[]?) | select(.id == $id) ]
			| first | .rect
			| "\($l) \(.width) \(.height)"')
		parent_layout=${1:-}
		width=${2:-0}
		height=${3:-0}

		if [ "$height" -gt "$width" ]; then
			want=splitv
		else
			want=splith
		fi
		[ "$want" = "$parent_layout" ] || swaymsg -q "$want"
	done
	;;
*)
	echo "usage: ${0##*/} [flatten|retile]" >&2
	exit 2
	;;
esac

swaymsg -q "workspace $ws"
[ -n "$focused" ] && swaymsg -q "[con_id=$focused] focus" || true
