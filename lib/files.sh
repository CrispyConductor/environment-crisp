# File placement for the module installer.
#
# Each module may carry up to four trees, all mirroring $HOME:
#
#   link/      symlinked into place, one link per file
#   copy/      copied into place (for files the owning app rewrites)
#   template/  copied only if the destination does not already exist
#   merge/     line-wise merged into the destination
#
# Sourced by install.sh.

# Directories already created (or reported, when dry running) this run.
MADE_DIRS=''

# install_tree <module> <kind> <srcroot>
install_tree() {
	local module="$1" kind="$2" srcroot="$3"
	[ -d "$srcroot" ] || return 0

	local src rel dest
	while IFS= read -r -d '' src; do
		rel="${src#"$srcroot"/}"
		dest="$TARGET_HOME/$rel"
		CURRENT_SRC="$src"
		case "$kind" in
			link)     place_link "$module" "$src" "$dest" "$rel" ;;
			copy)     place_copy "$module" "$src" "$dest" "$rel" ;;
			template) place_template "$module" "$src" "$dest" "$rel" ;;
			merge)    place_merge "$module" "$src" "$dest" "$rel" ;;
			*)        die "unknown tree kind: $kind" ;;
		esac
	done < <(find "$srcroot" -type f -print0 | LC_ALL=C sort -z)
}

# ensure_parent_dir <dest>
#
# Guarantee every component of the destination's parent is a real directory.
#
# This matters more than it looks: if ~/.config/nvim is still a symlink into a
# repo checkout (which is exactly what the old installer left behind), then
# writing to ~/.config/nvim/init.lua would resolve through the link and modify
# the repo instead of the home directory. Any symlink or plain file standing
# where a directory belongs is backed up and replaced.
ensure_parent_dir() {
	local dest="$1"
	local parent path component
	parent="$(dirname "$dest")"

	case "$parent" in
		"$TARGET_HOME"|"$TARGET_HOME"/*) ;;
		*) die "refusing to install outside \$TARGET_HOME: $dest" ;;
	esac

	path="$TARGET_HOME"
	# Walk the components below TARGET_HOME one at a time. Split without
	# touching IFS, which would otherwise stay changed for the rest of this
	# function and mangle how `run` reports the commands it executes.
	local rest="${parent#"$TARGET_HOME"}"
	rest="${rest#/}"
	[ -n "$rest" ] || return 0

	while [ -n "$rest" ]; do
		component="${rest%%/*}"
		if [ "$component" = "$rest" ]; then
			rest=''
		else
			rest="${rest#*/}"
		fi
		[ -n "$component" ] || continue

		path="$path/$component"
		if [ -L "$path" ] || { [ -e "$path" ] && [ ! -d "$path" ]; }; then
			warn "$(tilde "$path") is not a real directory; replacing it"
			backup_path "$path"
			run rm -rf "$path"
		fi
		if [ ! -d "$path" ]; then
			# In a dry run nothing is actually created, so without this the
			# same parent would be reported once per file underneath it.
			if ! printf '%s\n' "$MADE_DIRS" | grep -qxF -- "$path"; then
				run mkdir -p "$path"
				MADE_DIRS="$MADE_DIRS$path"$'\n'
			fi
		fi
	done
}

# resolve_existing <dest> - returns 0 to proceed, 1 to skip.
# Handles backup and removal of whatever is currently at dest.
resolve_existing() {
	local dest="$1" decision

	if [ ! -e "$dest" ] && [ ! -L "$dest" ]; then
		return 0
	fi

	decision="$(ask_existing "$dest")"
	if [ "$decision" = keep ]; then
		step "keeping existing $(tilde "$dest")"
		N_SKIPPED=$((N_SKIPPED + 1))
		return 1
	fi

	backup_path "$dest"
	run rm -rf "$dest"
	return 0
}

place_link() {
	local module="$1" src="$2" dest="$3" rel="$4"

	# Already pointing where we want it: nothing to do.
	if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
		verbose "already linked: $(tilde "$dest")"
		state_record "$module" link "$rel" "$src"
		N_SKIPPED=$((N_SKIPPED + 1))
		return 0
	fi

	ensure_parent_dir "$dest"
	resolve_existing "$dest" || return 0

	run ln -sfn "$src" "$dest"
	# Deliberately no chmod here: the destination is a symlink, so chmod would
	# change the mode of the file inside the repo.
	secure_ssh_dir "$rel"
	state_record "$module" link "$rel" "$src"
	N_LINKED=$((N_LINKED + 1))
	step "linked $(tilde "$dest")"
}

place_copy() {
	local module="$1" src="$2" dest="$3" rel="$4"

	if same_file "$src" "$dest"; then
		verbose "already current: $(tilde "$dest")"
		state_record "$module" copy "$rel" "$src"
		N_SKIPPED=$((N_SKIPPED + 1))
		return 0
	fi

	ensure_parent_dir "$dest"
	resolve_existing "$dest" || return 0

	run cp -p "$src" "$dest"
	apply_perms "$dest" "$rel"
	state_record "$module" copy "$rel" "$src"
	N_COPIED=$((N_COPIED + 1))
	step "copied $(tilde "$dest")"
}

place_template() {
	local module="$1" src="$2" dest="$3" rel="$4"

	if [ -e "$dest" ] || [ -L "$dest" ]; then
		verbose "template target exists, leaving alone: $(tilde "$dest")"
		state_record "$module" template "$rel" "$src"
		N_SKIPPED=$((N_SKIPPED + 1))
		return 0
	fi

	ensure_parent_dir "$dest"
	run cp -p "$src" "$dest"
	apply_perms "$dest" "$rel"
	state_record "$module" template "$rel" "$src"
	N_TEMPLATED=$((N_TEMPLATED + 1))
	good "created $(tilde "$dest")"
}

# place_merge - union the source's lines into the destination.
#
# Lines already present are not duplicated, so this is idempotent. For
# authorized_keys the comparison is on the key material (type + base64) rather
# than the whole line, so re-running does not add a second copy of a key whose
# trailing comment has changed.
place_merge() {
	local module="$1" src="$2" dest="$3" rel="$4"
	local key_mode=0 added=0 line sig

	[ "$(basename "$dest")" = authorized_keys ] && key_mode=1

	ensure_parent_dir "$dest"

	if [ "${DRY_RUN:-0}" = 1 ]; then
		printf '  %swould merge into%s %s\n' "$C_DIM" "$C_RESET" "$(tilde "$dest")"
		state_record "$module" merge "$rel" "$src"
		return 0
	fi

	[ -e "$dest" ] || : >"$dest"

	while IFS= read -r line || [ -n "$line" ]; do
		case "$line" in ''|\#*) continue ;; esac

		if [ "$key_mode" = 1 ]; then
			sig="$(printf '%s\n' "$line" | awk '{print $2}')"
			[ -n "$sig" ] || continue
			if awk -v s="$sig" '$2 == s { found = 1 } END { exit !found }' "$dest"; then
				continue
			fi
		elif grep -qxF -- "$line" "$dest"; then
			continue
		fi

		printf '%s\n' "$line" >>"$dest"
		added=$((added + 1))
	done <"$src"

	apply_perms "$dest" "$rel"
	state_record "$module" merge "$rel" "$src"

	if [ "$added" -gt 0 ]; then
		N_MERGED=$((N_MERGED + 1))
		good "merged $added new line(s) into $(tilde "$dest")"
	else
		N_SKIPPED=$((N_SKIPPED + 1))
		verbose "nothing new to merge into $(tilde "$dest")"
	fi
}

# apply_perms <dest> <rel> - tighten modes where the app demands it.
# Only called for real files, never through a symlink.
apply_perms() {
	local dest="$1" rel="$2"
	case "$rel" in
		.ssh/*)
			run chmod 600 "$dest"
			;;
	esac
	secure_ssh_dir "$rel"
}

secure_ssh_dir() {
	local rel="$1"
	case "$rel" in
		.ssh/*)
			if [ -d "$TARGET_HOME/.ssh" ]; then
				run chmod 700 "$TARGET_HOME/.ssh"
			fi
			;;
	esac
	return 0
}
