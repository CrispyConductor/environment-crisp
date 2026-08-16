#!/bin/sh
#
# Screen locker, used by both the Ctrl+Escape binding and swayidle's idle
# timeouts. Locks, then blanks the screens a couple of seconds later.
#
# This replaces /usr/share/sway/scripts/lock.sh, which invokes gtklock as:
#
#     gtklock --daemonize --follow-focus --idle-hide --start-hidden
#
# On this setup (sway, four outputs) that combination leaves the password form
# visible but insensitive: the entry cannot be typed into, and submitting sends
# an empty password, which then absorbs the 3 second pam_faildelay penalty from
# /etc/pam.d/gtklock ("auth include login") and reads as a hang. gtklock logs a
# stream of "gtk_widget_event: assertion 'WIDGET_REALIZED_FOR_EVENT' failed"
# while this happens - key events being delivered to an unrealized form.
#
# --follow-focus is documented as "may not work for all compositors,
# recommended for hyprland", and --start-hidden/--idle-hide are what leave the
# form unrealized for those events to miss. Plain "gtklock" is known good here,
# so this passes only --daemonize, which swayidle needs in order not to block
# on the lock (it runs with -w).
#
# The distro script is still the fallback when gtklock is absent, since it
# handles swaylock and the user swaylock hook.

BLANK_AFTER=2

# Already locked? Leave the running lock and its screen watcher alone. This
# also covers swayidle calling us for a timeout and again from before-sleep.
if pgrep -x gtklock >/dev/null 2>&1 || pgrep -x swaylock >/dev/null 2>&1; then
	exit 0
fi

if command -v gtklock >/dev/null 2>&1; then
	locker=gtklock
	gtklock --daemonize
else
	locker=swaylock
	/usr/share/sway/scripts/lock.sh
fi

# Blank the screens shortly after locking, and bring them back on the first
# input so the password form is visible when you return.
#
# sway keeps outputs powered off until something turns them on again - it does
# not wake them on input - so this needs a swayidle of its own. -C /dev/null is
# load-bearing: without it this instance would also load ~/.config/swayidle
# and re-run the whole idle schedule, locking and suspending in duplicate.
#
# The watcher lives only as long as the lock. It is torn down as soon as you
# come back (so the screens do not blank again between password keystrokes) or
# if the lock goes away, and the screens are forced back on either way.
# Fixed path, cleared here rather than at the end: swayidle forks its resume
# command, so the grandchild can touch this after we have torn the watcher
# down. Clearing it as the lock starts makes that leftover harmless.
flag="${XDG_RUNTIME_DIR:-/tmp}/sway-lock-resumed"
rm -f "$flag"

(
	# gtklock --daemonize returns before the daemon is up; wait for it, or the
	# "lock is gone" check below would fire immediately.
	n=0
	while [ "$n" -lt 50 ] && ! pgrep -x "$locker" >/dev/null 2>&1; do
		sleep 0.1
		n=$((n + 1))
	done

	swayidle -C /dev/null \
		timeout "$BLANK_AFTER" 'swaymsg "output * power off"' \
		resume "swaymsg \"output * power on\"; touch $flag" &
	watcher=$!

	while [ ! -e "$flag" ] && pgrep -x "$locker" >/dev/null 2>&1; do
		sleep 0.5
	done

	# swayidle runs its pending resume commands on SIGTERM, which touches the
	# flag again - so wait for it to be gone before clearing the flag.
	kill "$watcher" 2>/dev/null
	wait "$watcher" 2>/dev/null
	rm -f "$flag"
	swaymsg "output * power on"
) >/dev/null 2>&1 &

exit 0
