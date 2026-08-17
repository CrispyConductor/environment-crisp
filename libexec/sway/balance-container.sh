#!/bin/sh
#
# Give every child of the focused window's container an equal share.
# Sway has no balance/equalize command, so this builds one out of `resize set`.
#
# Two things about `resize set <axis> <n> ppt` shape the whole script:
#
#   - It trades space only with the child's IMMEDIATE next sibling, not across
#     the container. So one call cannot balance a row; a sweep is needed, and
#     each call pushes the leftover error one place along.
#   - The last child is therefore skipped: it absorbs whatever the sweep leaves.
#     Including it makes things oscillate, since it has no next sibling to take
#     from and pulls back off its left neighbour instead. Measured, five windows:
#     sweeping all five settles at 17.6 20.0 20.9 20.9 20.0 and stays there.
#
# Each pass takes out roughly half of what is left, so it needs a few. Measured
# on four windows skewed to 27.6/26.4/12.0/33.6, the spread after each pass:
#
#   1: 7.5    2: 3.8    3: 2.7    4: 1.8    5: 1.2
#
# It approaches an even split rather than reaching one - the last point or so is
# the granularity of `resize set` itself. So this is a fixed handful of passes,
# not a convergence loop: there is no exact answer to converge on, and five is
# already below what you can see.
#
# Which container gets balanced follows the $mod+e convention: the one holding
# the focused window, i.e. "even out the row/column I am in". Focus a window
# inside a nested container to balance that inner container instead.

set -eu

# Focused window, its container's layout, and that container's children.
#
# "first // empty" rather than plain "first": a focused FLOATING window is in its
# workspace's floating_nodes, not nodes, so nothing matches and first yields
# null. Left as null it would be fed to .nodes[] and jq would abort with "Cannot
# iterate over null" into the sway log. empty emits nothing instead, read leaves
# the variables blank, and the case below exits quietly - which is the right
# answer anyway, since floating windows have no share to divide.
read -r focused layout children <<EOF
$(swaymsg -t get_tree --raw | jq -r '
	( [ .. | objects | select(.focused? == true) | .id ] | first ) as $f
	| [ .. | objects | select(has("nodes") and ([ .nodes[].id ] | index($f))) ]
	| first // empty
	| "\($f) \(.layout) \([ .nodes[].id ] | join(" "))"')
EOF

case "$layout" in
splith) axis=width ;;
splitv) axis=height ;;
# tabbed and stacked children already fill the container; nothing to divide.
*) exit 0 ;;
esac

# shellcheck disable=SC2086
set -- $children
share=$((100 / $#))

for _ in 1 2 3 4 5; do
	# shellcheck disable=SC2086
	set -- $children
	# All but the last, which takes the remainder. One child leaves this empty.
	while [ $# -gt 1 ]; do
		swaymsg -q "[con_id=$1] focus; resize set $axis $share ppt"
		shift
	done
done

swaymsg -q "[con_id=$focused] focus"
