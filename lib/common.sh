# Shared helpers for the module installer.
# Sourced by install.sh; not executable on its own.

# --- output ---------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	C_RESET=$'\033[0m'
	C_DIM=$'\033[2m'
	C_RED=$'\033[31m'
	C_GREEN=$'\033[32m'
	C_YELLOW=$'\033[33m'
	C_BLUE=$'\033[34m'
	C_BOLD=$'\033[1m'
else
	C_RESET='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_BOLD=''
fi

log()     { printf '%s\n' "$*"; }
info()    { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
step()    { printf '  %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
good()    { printf '  %s%s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn()    { printf '%swarning:%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err()     { printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
die()     { err "$*"; exit 1; }
verbose() { [ "${VERBOSE:-0}" = 1 ] && step "$*"; return 0; }

# Counters reported in the run summary.
N_LINKED=0 N_COPIED=0 N_TEMPLATED=0 N_MERGED=0 N_SKIPPED=0 N_BACKED_UP=0 N_REMOVED=0

# --- dry run --------------------------------------------------------------

# run <command...> - execute unless dry-running.
run() {
	if [ "${DRY_RUN:-0}" = 1 ]; then
		printf '  %swould run:%s %s\n' "$C_DIM" "$C_RESET" "$*"
		return 0
	fi
	"$@"
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- prompting ------------------------------------------------------------

# ask_existing <dest> - decide what to do about an existing destination.
# Echoes "overwrite" or "keep". Honours EXISTING_POLICY, and remembers
# an all-files answer in EXISTING_POLICY so we only ask once if asked to.
ask_existing() {
	local dest="$1" reply

	case "$EXISTING_POLICY" in
		overwrite|keep) printf '%s\n' "$EXISTING_POLICY"; return 0 ;;
	esac

	# Non-interactive stdin cannot answer; default to the safe option.
	if [ ! -t 0 ]; then
		warn "not a terminal, keeping existing $dest (use --existing to choose)"
		printf 'keep\n'
		return 0
	fi

	while true; do
		printf '%s exists. [o]verwrite / [k]eep / [d]iff / overwrite [A]ll / keep all [K]? ' \
			"${dest/#$TARGET_HOME/\~}" >&2
		read -r reply || reply=k
		case "$reply" in
			o|O)  printf 'overwrite\n'; return 0 ;;
			k)    printf 'keep\n'; return 0 ;;
			A)    EXISTING_POLICY=overwrite; printf 'overwrite\n'; return 0 ;;
			K)    EXISTING_POLICY=keep;      printf 'keep\n'; return 0 ;;
			d|D)  show_diff "$dest" "$CURRENT_SRC" >&2 ;;
			q|Q)  die 'aborted' ;;
			*)    printf 'Please answer o, k, d, A, K or q.\n' >&2 ;;
		esac
	done
}

show_diff() {
	local dest="$1" src="$2"
	if [ -z "$src" ] || [ ! -f "$src" ] || [ ! -f "$dest" ]; then
		printf 'no textual diff available\n'
		return 0
	fi
	diff -u "$dest" "$src" || true
}

# --- backups --------------------------------------------------------------

# Backup destination for this run. Flat per-run directory, never nested
# inside a previous backup, and contents are always dereferenced so a
# backed-up symlink becomes a real file rather than a pointer into the repo.
init_backup_dir() {
	if [ -z "${BACKUP_DIR:-}" ]; then
		BACKUP_DIR="$TARGET_HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
	fi
}

# backup_path <dest> - copy dest into the backup dir, dereferencing links.
backup_path() {
	local dest="$1" rel target
	rel="${dest#"$TARGET_HOME"/}"
	target="$BACKUP_DIR/$rel"

	# A dangling symlink has nothing worth preserving.
	if [ -L "$dest" ] && [ ! -e "$dest" ]; then
		verbose "discarding dangling symlink $dest"
		return 0
	fi

	if [ "${DRY_RUN:-0}" = 1 ]; then
		printf '  %swould back up%s %s\n' "$C_DIM" "$C_RESET" "${dest/#$TARGET_HOME/\~}"
		N_BACKED_UP=$((N_BACKED_UP + 1))
		return 0
	fi

	mkdir -p "$(dirname "$target")"
	# -L dereferences: we want real content in the backup, not a link.
	cp -aL "$dest" "$target" 2>/dev/null || cp -a "$dest" "$target"
	N_BACKED_UP=$((N_BACKED_UP + 1))
	verbose "backed up $dest -> $target"
}

# --- misc -----------------------------------------------------------------

# tilde <path> - shorten for display.
tilde() { printf '%s\n' "${1/#$TARGET_HOME/\~}"; }

# same_file <a> <b> - true if both exist with identical content.
same_file() {
	[ -f "$1" ] && [ -f "$2" ] && cmp -s "$1" "$2"
}

# ensure_line <file> <line> - append line to file unless already present.
# Creates the file if missing. Idempotent.
ensure_line() {
	local file="$1" line="$2"
	if [ "${DRY_RUN:-0}" = 1 ]; then
		if [ ! -f "$file" ] || ! grep -qxF -- "$line" "$file" 2>/dev/null; then
			printf '  %swould append to%s %s: %s\n' "$C_DIM" "$C_RESET" "$(tilde "$file")" "$line"
		fi
		return 0
	fi
	[ -f "$file" ] || { mkdir -p "$(dirname "$file")"; : >"$file"; }
	if ! grep -qxF -- "$line" "$file"; then
		printf '%s\n' "$line" >>"$file"
		step "appended to $(tilde "$file"): $line"
	fi
}
