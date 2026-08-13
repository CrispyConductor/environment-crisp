#!/usr/bin/env bash
#
# Install one or more dotfile modules.
#
#   ./install.sh                      # the 'default' profile (base + fish)
#   ./install.sh base fish            # named modules
#   ./install.sh -p workstation       # a profile
#   ./install.sh --list               # what is available
#
# See doc/modules.md for the module format.

set -euo pipefail

# Dependency resolution uses associative arrays, which need bash 4. macOS
# still ships bash 3.2, so say so plainly rather than failing later with a
# confusing `declare: -A: invalid option`.
if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
	echo "install.sh needs bash 4 or newer (this is ${BASH_VERSION:-unknown})." >&2
	echo 'On macOS: brew install bash, then re-run this script.' >&2
	exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
MODULES_DIR="$REPO_DIR/modules"
PROFILES_DIR="$REPO_DIR/profiles"

# shellcheck source=lib/common.sh
. "$REPO_DIR/lib/common.sh"
# shellcheck source=lib/files.sh
. "$REPO_DIR/lib/files.sh"
# shellcheck source=lib/state.sh
. "$REPO_DIR/lib/state.sh"
# shellcheck source=lib/packages.sh
. "$REPO_DIR/lib/packages.sh"

# --- defaults -------------------------------------------------------------

TARGET_HOME="${HOME}"
EXISTING_POLICY=ask
DRY_RUN=0
VERBOSE=0
DO_PACKAGES=1
DO_HOOKS=1
DO_UNINSTALL=0
BACKUP_DIR=''
CURRENT_SRC=''
ASK_RESULT=''
APT_NEEDS_UPDATE=0
PROFILE=''
declare -a REQUESTED=()

usage() {
	cat <<'EOF'
Usage: install.sh [options] [module...]

With no modules and no --profile, the 'default' profile is installed.

Options:
  -p, --profile NAME      install the module set listed in profiles/NAME
  -e, --existing POLICY   what to do about files that already exist:
                            ask (default), overwrite, keep
  -n, --dry-run           report what would change without changing anything
      --home DIR          install into DIR instead of $HOME (for testing)
      --no-packages       skip package installation
      --no-hooks          skip module install hooks
      --uninstall         remove the listed modules' installed files
  -l, --list              list available modules and profiles
  -v, --verbose           more detail
  -h, --help              this message
EOF
}

# --- argument parsing -----------------------------------------------------

while [ $# -gt 0 ]; do
	case "$1" in
		-p|--profile)   PROFILE="${2:?--profile needs a name}"; shift 2 ;;
		--profile=*)    PROFILE="${1#*=}"; shift ;;
		-e|--existing)  EXISTING_POLICY="${2:?--existing needs a policy}"; shift 2 ;;
		--existing=*)   EXISTING_POLICY="${1#*=}"; shift ;;
		-n|--dry-run)   DRY_RUN=1; shift ;;
		--home)         TARGET_HOME="${2:?--home needs a directory}"; shift 2 ;;
		--home=*)       TARGET_HOME="${1#*=}"; shift ;;
		--no-packages)  DO_PACKAGES=0; shift ;;
		--no-hooks)     DO_HOOKS=0; shift ;;
		--uninstall)    DO_UNINSTALL=1; shift ;;
		-l|--list)      LIST_ONLY=1; shift ;;
		-v|--verbose)   VERBOSE=1; shift ;;
		-h|--help)      usage; exit 0 ;;
		--)             shift; break ;;
		-*)             die "unknown option: $1 (try --help)" ;;
		*)              REQUESTED+=("$1"); shift ;;
	esac
done
while [ $# -gt 0 ]; do REQUESTED+=("$1"); shift; done

case "$EXISTING_POLICY" in
	ask|overwrite|keep) ;;
	*) die "--existing must be ask, overwrite or keep (got '$EXISTING_POLICY')" ;;
esac

TARGET_HOME="${TARGET_HOME%/}"
[ -d "$TARGET_HOME" ] || die "target home does not exist: $TARGET_HOME"

# --- module metadata ------------------------------------------------------

module_dir() { printf '%s\n' "$MODULES_DIR/$1"; }

module_exists() { [ -d "$MODULES_DIR/$1" ]; }

# module_load_meta <name> - populate MODULE_* from the module's meta file.
module_load_meta() {
	local name="$1" dir
	dir="$(module_dir "$name")"

	local description='' requires='' platform='any' pkgmgr=''
	if [ -f "$dir/meta" ]; then
		# shellcheck disable=SC1090
		. "$dir/meta"
	fi

	MODULE_NAME="$name"
	MODULE_DIR="$dir"
	MODULE_DESCRIPTION="$description"
	MODULE_REQUIRES="$requires"
	MODULE_PLATFORM="$platform"
	MODULE_PKGMGR="$pkgmgr"
}

list_modules() {
	local dir name
	for dir in "$MODULES_DIR"/*; do
		[ -d "$dir" ] || continue
		name="$(basename "$dir")"
		module_load_meta "$name"
		printf '  %s%-22s%s %s\n' "$C_BOLD" "$name" "$C_RESET" "$MODULE_DESCRIPTION"
	done
}

list_profiles() {
	local f name
	for f in "$PROFILES_DIR"/*; do
		[ -f "$f" ] || continue
		name="$(basename "$f")"
		printf '  %s%-22s%s %s\n' "$C_BOLD" "$name" "$C_RESET" "$(read_list "$f" | tr '\n' ' ')"
	done
}

if [ "${LIST_ONLY:-0}" = 1 ]; then
	info 'modules'
	list_modules
	printf '\n'
	info 'profiles'
	list_profiles
	exit 0
fi

# --- platform detection ---------------------------------------------------

detect_platform() {
	case "$(uname -s)" in
		Darwin) printf 'macos\n' ;;
		Linux)  printf 'linux\n' ;;
		*)      printf 'unknown\n' ;;
	esac
}
PLATFORM="$(detect_platform)"

platform_ok() {
	case "$1" in
		any|"") return 0 ;;
		"$PLATFORM") return 0 ;;
		*) return 1 ;;
	esac
}

# --- module resolution ----------------------------------------------------

declare -a RESOLVED=()
declare -A RESOLVING=()
declare -A DONE=()

resolve_module() {
	local name="$1" dep

	[ -n "${DONE[$name]:-}" ] && return 0
	[ -n "${RESOLVING[$name]:-}" ] && die "dependency cycle involving module '$name'"

	module_exists "$name" || die "no such module: $name (try --list)"

	RESOLVING[$name]=1
	module_load_meta "$name"

	if ! platform_ok "$MODULE_PLATFORM"; then
		die "module '$name' targets $MODULE_PLATFORM but this is $PLATFORM"
	fi

	for dep in $MODULE_REQUIRES; do
		resolve_module "$dep"
	done

	unset "RESOLVING[$name]"
	DONE[$name]=1
	RESOLVED+=("$name")
}

# Work out the requested set.
#
# Uninstall never falls back to the default profile: `--uninstall` with no
# arguments would otherwise quietly remove base and fish.
if [ "$DO_UNINSTALL" = 1 ]; then
	if [ "${#REQUESTED[@]}" -eq 0 ] && [ -z "$PROFILE" ]; then
		die '--uninstall needs explicit module names (or --profile)'
	fi
elif [ "${#REQUESTED[@]}" -eq 0 ]; then
	[ -n "$PROFILE" ] || PROFILE=default
fi

if [ -n "$PROFILE" ]; then
	profile_file="$PROFILES_DIR/$PROFILE"
	[ -f "$profile_file" ] || die "no such profile: $PROFILE"
	while IFS= read -r m; do
		REQUESTED+=("$m")
	done < <(read_list "$profile_file")
fi

[ "${#REQUESTED[@]}" -gt 0 ] || die 'no modules to install'

# Uninstalling must not follow `requires`. Pulling in dependencies there would
# mean `--uninstall fish` also removed base, which other modules still need.
if [ "$DO_UNINSTALL" = 1 ]; then
	declare -a TO_REMOVE=()
	declare -A REMOVE_SEEN=()
	for m in "${REQUESTED[@]}"; do
		module_exists "$m" || die "no such module: $m (try --list)"
		[ -n "${REMOVE_SEEN[$m]:-}" ] && continue
		REMOVE_SEEN[$m]=1
		TO_REMOVE+=("$m")
	done
else
	for m in "${REQUESTED[@]}"; do
		resolve_module "$m"
	done
fi

# --- uninstall path -------------------------------------------------------

state_init
pkg_init
init_backup_dir

if [ "$DO_UNINSTALL" = 1 ]; then
	info "uninstalling: ${TO_REMOVE[*]}"
	for m in "${TO_REMOVE[@]}"; do
		info "module: $m"
		state_uninstall "$m"
	done
	log ''
	good "removed $N_REMOVED file(s)"
	exit 0
fi

# --- install --------------------------------------------------------------

info "installing modules: ${RESOLVED[*]}"
[ "$TARGET_HOME" = "$HOME" ] || warn "target home is $TARGET_HOME (not \$HOME)"
if [ "$DRY_RUN" = 1 ]; then
	warn 'dry run: nothing will be modified'
fi

# Packages first: module hooks and later steps may need the tools they bring in.
if [ "$DO_PACKAGES" = 1 ]; then
	for m in "${RESOLVED[@]}"; do
		module_load_meta "$m"
		pkg_collect "$MODULE_DIR"
	done
	pkg_install_all
else
	verbose 'skipping packages (--no-packages)'
fi

# The repo anchor. Every shell rc, tmux.conf and init.lua reaches back into the
# repo through this path, so it has to exist before any config is used.
if [ "$REPO_DIR" = "$TARGET_HOME/.userenv" ]; then
	# The checkout already lives at the anchor path. Removing it here would
	# delete the repo we are installing from.
	verbose "repo is the anchor itself: $(tilde "$TARGET_HOME/.userenv")"
elif [ -L "$TARGET_HOME/.userenv" ] && [ "$(readlink "$TARGET_HOME/.userenv")" = "$REPO_DIR" ]; then
	verbose "repo anchor already correct: $(tilde "$TARGET_HOME/.userenv")"
elif [ -e "$TARGET_HOME/.userenv" ] && [ ! -L "$TARGET_HOME/.userenv" ]; then
	die "$(tilde "$TARGET_HOME/.userenv") exists and is not a symlink; move it aside first"
else
	info "linking repo anchor $(tilde "$TARGET_HOME/.userenv") -> $REPO_DIR"
	run rm -f "$TARGET_HOME/.userenv"
	run ln -sfn "$REPO_DIR" "$TARGET_HOME/.userenv"
fi

for m in "${RESOLVED[@]}"; do
	module_load_meta "$m"
	info "module: $m${MODULE_DESCRIPTION:+ - $MODULE_DESCRIPTION}"

	install_tree "$m" link     "$MODULE_DIR/link"
	install_tree "$m" copy     "$MODULE_DIR/copy"
	install_tree "$m" template "$MODULE_DIR/template"
	install_tree "$m" merge    "$MODULE_DIR/merge"
done

if [ "$DO_HOOKS" = 1 ]; then
	for m in "${RESOLVED[@]}"; do
		module_load_meta "$m"
		[ -f "$MODULE_DIR/install.sh" ] || continue
		info "hook: $m"
		# Sourced, not executed, so hooks can use the helpers above and see
		# TARGET_HOME / REPO_DIR / DRY_RUN.
		# shellcheck disable=SC1090
		. "$MODULE_DIR/install.sh"
	done
else
	verbose 'skipping module hooks (--no-hooks)'
fi

# Prune only after the hooks have run.
#
# Hooks register files too - the base hook is what records everything under
# ~/.local/bin - so pruning inside the install loop above would look at a
# half-built picture of this run, delete those entries every time, and let the
# hook re-create them.
#
# For the same reason, --no-hooks skips pruning altogether: with the hooks
# skipped this run never learns about the files they own, and pruning against
# that incomplete picture would delete them. Skipping setup steps should not
# uninstall anything.
if [ "$DO_HOOKS" = 1 ]; then
	for m in "${RESOLVED[@]}"; do
		state_prune_module "$m"
	done
	state_commit "${RESOLVED[@]}"
else
	verbose 'skipping stale-file cleanup (--no-hooks means an incomplete picture of this run)'
	# Record what we did place, but merge instead of replacing: the rows for
	# files the skipped hooks own are still valid and must not be dropped.
	STATE_MERGE=1 state_commit "${RESOLVED[@]}"
fi

# --- summary --------------------------------------------------------------

log ''
info 'summary'
step "linked:    $N_LINKED"
step "copied:    $N_COPIED"
step "created:   $N_TEMPLATED"
step "merged:    $N_MERGED"
step "unchanged: $N_SKIPPED"
if [ "$N_REMOVED" -gt 0 ]; then
	step "removed:   $N_REMOVED"
fi
if [ "$N_BACKED_UP" -gt 0 ]; then
	step "backed up: $N_BACKED_UP -> $(tilde "$BACKUP_DIR")"
fi
log ''
good 'done'
