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
# Criteria selection is what makes the park a one-liner: [workspace=__focused__]
# matches views only, never the containers holding them, so one command
# relocates every window and takes the scaffolding with it.
#
# The scratch workspace is numbered absurdly high and is never focused, so it
# does not appear in waybar or disturb what is on screen; sway destroys it when
# the last window leaves.
#
# Workspaces are addressed by number throughout - see the comment on $ws below
# for why names are unusable here.

set -eu

MODE="${1:-flatten}"
SCRATCH=99999

# Everything here addresses workspaces by NUMBER, never by name.
#
# Ubuntu Sway Remix autostarts /usr/share/sway/scripts/autoname-workspaces.py,
# which rewrites every workspace's name on each window event to carry per-app
# icons - workspace 8 is actually named "8:   ". Emptying it rewrites the
# name again, and sway destroys an unfocused empty workspace outright. Capture
# the name up front and "move back to <name>" then matches nothing, so sway
# CREATES a second workspace with that literal string, parsing 8 out of the
# leading digits. The result is two workspaces both showing as 8 in waybar with
# the windows split between them.
#
# autoname-workspaces.py's own header says to address workspaces as
# "workspace number N" for precisely this reason. Numbers are stable across its
# renaming; names are not.
ws=$(swaymsg -t get_workspaces --raw | jq -r '.[] | select(.focused) | .num')
if [ -z "$ws" ] || [ "$ws" = "null" ] || [ "$ws" -lt 0 ] 2>/dev/null; then
	notify-send "Retile" "Focused workspace has no number; this script addresses workspaces by number only"
	exit 1
fi

# Collect the views before moving anything: afterwards they are on the scratch
# workspace and the original selection is no longer expressible.
#
# Selecting by .num rather than .name, for the same reason as above.
ids=$(swaymsg -t get_tree --raw | jq -r --argjson ws "$ws" '
	[ recurse(.nodes[]?, .floating_nodes[]?)
	  | select(.type == "workspace" and .num == $ws) ]
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
#
# [workspace=__focused__] matches every window on the currently focused
# workspace without naming it, which sidesteps the renaming entirely on this
# side. The scratch workspace gets renamed by autoname too, which is why the
# windows come back by con_id rather than by matching on it.
swaymsg -q "[workspace=__focused__] move container to workspace number $SCRATCH"

case "$MODE" in
flatten)
	# Back by con_id, in the order they were collected, so they arrive as flat
	# siblings. Not one bulk [workspace=...] match: autoname-workspaces.py has
	# by now renamed the scratch workspace to carry icons too, so matching it by
	# name would miss. The ids were captured before any of this started.
	for id in $ids; do
		swaymsg -q "[con_id=$id] move container to workspace number $ws"
	done
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
		swaymsg -q "[con_id=$id] focus; [con_id=$id] move container to workspace number $ws"
		swaymsg -q "workspace number $ws"

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

swaymsg -q "workspace number $ws"
[ -n "$focused" ] && swaymsg -q "[con_id=$focused] focus" || true
