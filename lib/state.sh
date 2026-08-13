# Install-state tracking.
#
# Every destination the installer creates is recorded. This gives two things:
#
#   1. `install.sh --uninstall <module>` can find what to remove.
#   2. When a module stops providing a file - because it moved to another
#      module, got renamed, or was dropped - the stale destination is cleaned
#      up on the next install instead of lingering as a broken symlink.
#
# (2) is what makes future reorganizations of this repo self-healing. The
# one-time unlink-dotfiles.sh migration exists only because the installer that
# came before this one kept no record of what it had done.
#
# Format: one TAB-separated record per line
#   module <TAB> kind <TAB> path-relative-to-home <TAB> source-path
#
# Sourced by install.sh.

state_init() {
	# XDG_STATE_HOME describes the *invoking* user's home, so it is only
	# meaningful when we are installing there. Honouring it under --home would
	# make a test run read and then overwrite the real machine's state file.
	if [ "$TARGET_HOME" = "$HOME" ] && [ -n "${XDG_STATE_HOME:-}" ]; then
		STATE_DIR="$XDG_STATE_HOME/userenv"
	else
		STATE_DIR="$TARGET_HOME/.local/state/userenv"
	fi
	STATE_FILE="$STATE_DIR/installed.tsv"
	STATE_NEW="$(mktemp)"
	trap 'rm -f "$STATE_NEW"' EXIT
}

# state_record <module> <kind> <rel> <src>
state_record() {
	printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >>"$STATE_NEW"
}

# state_entries_for <module> - print recorded "kind<TAB>rel" for a module.
state_entries_for() {
	local module="$1"
	[ -f "$STATE_FILE" ] || return 0
	awk -F'\t' -v m="$module" '$1 == m { print $2 "\t" $3 }' "$STATE_FILE"
}

# state_prune_module <module>
#
# Remove destinations that this module used to install but no longer does.
#
# Only symlinks pointing into this repo are deleted. A real file is never
# removed automatically - it might hold content the user cares about - so it is
# reported instead.
state_prune_module() {
	local module="$1"
	[ -f "$STATE_FILE" ] || return 0

	local kind rel dest
	while IFS=$'\t' read -r kind rel; do
		[ -n "$rel" ] || continue
		# Still provided by *any* module in this run? Then keep it.
		#
		# Deliberately not scoped to this module: when a file moves from one
		# module to another, the module that lost it would otherwise delete
		# the copy the new owner just installed.
		if awk -F'\t' -v r="$rel" \
			'$3 == r { found = 1 } END { exit !found }' "$STATE_NEW"; then
			continue
		fi

		dest="$TARGET_HOME/$rel"
		if [ -L "$dest" ]; then
			local target
			target="$(readlink "$dest")"
			case "$target" in
				"$REPO_DIR"/*)
					run rm -f "$dest"
					N_REMOVED=$((N_REMOVED + 1))
					step "removed stale link $(tilde "$dest")"
					;;
				*)
					verbose "leaving $(tilde "$dest") (links outside this repo)"
					;;
			esac
		elif [ -e "$dest" ]; then
			warn "$module no longer provides $(tilde "$dest"); left in place (not a link into this repo)"
		fi
	done < <(state_entries_for "$module")
}

# state_commit <module...> - rewrite the state file.
# Entries for modules touched this run are replaced; everything else is kept.
state_commit() {
	if [ "${DRY_RUN:-0}" = 1 ]; then
		verbose 'dry run: not writing install state'
		return 0
	fi

	local tmp
	tmp="$(mktemp)"

	if [ -f "$STATE_FILE" ]; then
		if [ "${STATE_MERGE:-0}" = 1 ]; then
			# Additive: this run did not see everything (hooks were skipped),
			# so every existing row stays and the new ones are added on top.
			cat "$STATE_FILE" >>"$tmp"
		else
			# Carry over entries for modules this run did not touch.
			#
			# awk compares field 1 exactly, which sidesteps two problems a
			# regex had here: grep -E reads "\t" as a literal 't' rather than a
			# tab, and module names would need escaping. Getting that wrong
			# dropped the rows of any module whose name was a prefix of this
			# one, while keeping the stale rows it was meant to replace.
			local m
			{
				for m in "$@"; do
					printf '%s\n' "$m"
				done
			} >"$tmp.mods"

			awk -F'\t' '
				NR == FNR { touched[$0] = 1; next }
				!($1 in touched)
			' "$tmp.mods" "$STATE_FILE" >>"$tmp"

			rm -f "$tmp.mods"
		fi
	fi

	LC_ALL=C sort -u "$STATE_NEW" >>"$tmp"

	mkdir -p "$STATE_DIR"
	LC_ALL=C sort -u "$tmp" >"$STATE_FILE"
	rm -f "$tmp"
	verbose "recorded install state in $(tilde "$STATE_FILE")"
}

# state_uninstall <module> - remove everything a module installed.
state_uninstall() {
	local module="$1"
	if [ ! -f "$STATE_FILE" ]; then
		warn "no install state found; nothing to uninstall"
		return 0
	fi

	local found=0 kind rel dest target
	while IFS=$'\t' read -r kind rel; do
		[ -n "$rel" ] || continue
		found=1
		dest="$TARGET_HOME/$rel"

		if [ -L "$dest" ]; then
			target="$(readlink "$dest")"
			case "$target" in
				"$REPO_DIR"/*)
					run rm -f "$dest"
					N_REMOVED=$((N_REMOVED + 1))
					step "removed $(tilde "$dest")"
					;;
				*)
					warn "skipping $(tilde "$dest") (links outside this repo)"
					;;
			esac
		elif [ -e "$dest" ]; then
			# Copies, templates and merged files may carry local edits.
			case "$kind" in
				copy)
					if backup_path "$dest"; then
						run rm -f "$dest"
						N_REMOVED=$((N_REMOVED + 1))
						step "removed $(tilde "$dest") (backed up)"
					else
						warn "leaving $(tilde "$dest") (could not back it up)"
					fi
					;;
				*)
					warn "leaving $(tilde "$dest") ($kind - may contain local content)"
					;;
			esac
		fi
	done < <(state_entries_for "$module")

	[ "$found" = 1 ] || warn "no recorded files for module '$module'"

	if [ "${DRY_RUN:-0}" != 1 ]; then
		local tmp
		tmp="$(mktemp)"
		awk -F'\t' -v m="$module" '$1 != m' "$STATE_FILE" >"$tmp"
		mv "$tmp" "$STATE_FILE"
	fi
}
