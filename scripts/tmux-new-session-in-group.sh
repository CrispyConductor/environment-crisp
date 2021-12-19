#!/bin/bash

# Get current session information
read -r oldsessid oldsessname grp <<< "$(tmux display-message -p '#{session_id} #{session_name} #{session_group}')"

if [ "$grp" = "" ]; then
	# Existing session has no group, so create a new one
	newsessname="${oldsessname}_B"
	tmux new-session -d -t "$oldsessname" -s "$newsessname"
else
	# Find bottom-sorted session name in group
	lastsessname="$(tmux list-sessions -F '#{session_group} #{session_name}' | grep '^'$grp' ' | sort | tail -n1 | cut -d ' ' -f 2)"

	# Detect if it already has an _X letter suffix
	if grep '_[A-Z]$' <<< "$lastsessname" >/dev/null; then
		# Pull out the letter suffix
		suffix="$(echo -n "$lastsessname" | tail -c1)"
		# "Increment" the letter suffix
		newsuffix="$(tr 'ABCDEFGHIJKLMNOPQRSTUVWXY' 'BCDEFGHIJKLMNOPQRSTUVWXYZ' <<< "$suffix")"
		# New session name
		newsessname="$(echo -n "$lastsessname" | head -c -1)${newsuffix}"
		while [ "$newsessname" = "$lastsessname" ]; do
			newsessname="${newsessname}_"
		done
	else
		# New session name is suffixed as _B
		newsessname="${lastsessname}_B"
	fi

	# Make new session
	tmux new-session -d -t "$grp" -s "$newsessname"
fi

# Switch to new session
tmux switch-client -t "$newsessname"


