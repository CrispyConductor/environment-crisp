#!/usr/bin/env bash
#
# One-time migration: turn dotfile symlinks into real files.
#
# Run this on a machine that still has the OLD layout of this repo installed,
# BEFORE pulling the new one. It finds every symlink in your home directory
# that points into the repo checkout and replaces it with a real copy of the
# file it pointed at.
#
# Why: the new layout moves nearly every file. Once you pull, the old symlinks
# would all dangle, and the installer would be replacing broken links rather
# than real files. Converting them first means nothing breaks between the pull
# and the re-install, and the installer sees ordinary files it can back up.
#
# This script is deliberately self-contained - it depends on nothing from the
# repo, so it can be downloaded and run on its own:
#
#   curl -fsSLO https://raw.githubusercontent.com/CrispyConductor/environment-crisp/master/unlink-dotfiles.sh
#   bash unlink-dotfiles.sh --dry-run     # look first
#   bash unlink-dotfiles.sh
#
# Then:
#
#   cd <repo> && git pull
#   ./install.sh -p default
#
# You should only ever need this once. The new installer records what it
# installs, so future moves are cleaned up automatically.

set -euo pipefail

DRY_RUN=0
LIST_ONLY=0
CLEAN_BACKUPS=0
REPO=''
MAXDEPTH=6

usage() {
	cat <<'EOF'
Usage: unlink-dotfiles.sh [options]

Options:
      --repo DIR            repo checkout to look for (default: target of ~/.userenv)
  -n, --dry-run             report what would change, change nothing
  -l, --list                just list the symlinks found, then exit
      --clean-old-backups   also remove ~/.dotfiles_backup, whose contents are
                            symlinks into the repo rather than real files
  -h, --help                this message
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		--repo)              REPO="${2:?--repo needs a directory}"; shift 2 ;;
		--repo=*)            REPO="${1#*=}"; shift ;;
		-n|--dry-run)        DRY_RUN=1; shift ;;
		-l|--list)           LIST_ONLY=1; shift ;;
		--clean-old-backups) CLEAN_BACKUPS=1; shift ;;
		-h|--help)           usage; exit 0 ;;
		*) echo "unknown option: $1" >&2; usage; exit 1 ;;
	esac
done

if [ -t 1 ]; then
	C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
	C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
	C_RESET='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
fi

info() { printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
step() { printf '  %s\n' "$*"; }
warn() { printf '%swarning:%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# --- locate the repo ------------------------------------------------------

if [ -z "$REPO" ]; then
	[ -L "$HOME/.userenv" ] || die "~/.userenv is not a symlink; pass --repo <checkout>"
	REPO="$(readlink -f "$HOME/.userenv")" || die 'could not resolve ~/.userenv'
fi

REPO="${REPO%/}"
[ -d "$REPO" ] || die "not a directory: $REPO"

info "looking for symlinks into $REPO"

# --- find candidates ------------------------------------------------------
#
# find does not follow symlinks without -L, so it will not descend through a
# linked directory into the repo itself.
#
# ~/.dotfiles_backup is skipped: the old installer moved symlinks into it
# rather than dereferencing them, so everything in there is a pointer into the
# repo rather than a real backup. Nothing in it is worth converting.

declare -a LINKS=()

while IFS= read -r link; do
	target="$(readlink "$link")"
	case "$target" in
		"$REPO"|"$REPO"/*) LINKS+=("$link") ;;
	esac
done < <(
	find "$HOME" -maxdepth "$MAXDEPTH" \
		\( -name .git \
		   -o -name node_modules \
		   -o -name .cache \
		   -o -name .dotfiles_backup \
		   -o -name .dotfiles-backup \
		   -o -name snap \
		   -o -path "$HOME/.local/share/nvim/lazy" \
		   -o -path "$HOME/.tmux/plugins" \
		   -o -path "$REPO" \
		\) -prune -o -type l -print 2>/dev/null
)

# The repo anchor itself stays: the dotfiles we are about to make real still
# reference ~/.userenv/libexec/... at runtime, and it has to keep working
# between now and the re-install.
declare -a FILTERED=()
for link in ${LINKS+"${LINKS[@]}"}; do
	if [ "$link" = "$HOME/.userenv" ]; then
		continue
	fi
	FILTERED+=("$link")
done
LINKS=(${FILTERED+"${FILTERED[@]}"})

if [ "${#LINKS[@]}" -eq 0 ]; then
	info 'no symlinks into the repo found - nothing to do'
else
	info "found ${#LINKS[@]} symlink(s) into the repo"
fi

if [ "$LIST_ONLY" = 1 ]; then
	for link in ${LINKS+"${LINKS[@]}"}; do
		printf '  %s %s->%s %s\n' "${link/#$HOME/\~}" "$C_DIM" "$C_RESET" "$(readlink "$link")"
	done
	exit 0
fi

# --- convert --------------------------------------------------------------

converted=0
skipped=0

for link in ${LINKS+"${LINKS[@]}"}; do
	shown="${link/#$HOME/\~}"

	if [ ! -e "$link" ]; then
		warn "$shown is a dangling link (target is gone); removing it"
		[ "$DRY_RUN" = 1 ] || rm -f "$link"
		skipped=$((skipped + 1))
		continue
	fi

	if [ "$DRY_RUN" = 1 ]; then
		if [ -d "$link" ]; then
			step "would replace directory link $shown with a real copy"
		else
			step "would replace $shown with a real copy"
		fi
		converted=$((converted + 1))
		continue
	fi

	tmp="$link.unlink-tmp.$$"
	rm -rf "$tmp"

	# -L dereferences, so a linked directory becomes a real directory tree and
	# a linked file becomes a real file.
	if ! cp -aL "$link" "$tmp"; then
		warn "could not copy $shown; leaving it alone"
		rm -rf "$tmp"
		skipped=$((skipped + 1))
		continue
	fi

	rm -f "$link"
	mv "$tmp" "$link"
	step "$shown is now a real file"
	converted=$((converted + 1))
done

# --- the old backup directory ---------------------------------------------

if [ -d "$HOME/.dotfiles_backup" ]; then
	dangling="$(find "$HOME/.dotfiles_backup" -type l 2>/dev/null | wc -l)"
	realfiles="$(find "$HOME/.dotfiles_backup" -type f 2>/dev/null | wc -l)"

	if [ "$CLEAN_BACKUPS" = 1 ]; then
		info "removing ~/.dotfiles_backup ($dangling link(s), $realfiles real file(s))"
		if [ "$realfiles" -gt 0 ]; then
			warn "it contains $realfiles real file(s); check them before rerunning with --clean-old-backups"
			warn 'not removing'
		elif [ "$DRY_RUN" = 1 ]; then
			step 'would remove ~/.dotfiles_backup'
		else
			rm -rf "$HOME/.dotfiles_backup"
			step 'removed'
		fi
	elif [ "$dangling" -gt 0 ]; then
		info "~/.dotfiles_backup holds $dangling symlink(s) into the repo and $realfiles real file(s)"
		step 'those "backups" are pointers into the repo, not copies - pass --clean-old-backups to delete them'
	fi
fi

# --- summary --------------------------------------------------------------

printf '\n'
if [ "$DRY_RUN" = 1 ]; then
	info "dry run: $converted file(s) would be converted, $skipped skipped"
	printf '  run again without --dry-run to apply\n'
else
	printf '%s==>%s converted %s file(s), skipped %s\n' "$C_GREEN" "$C_RESET" "$converted" "$skipped"
	cat <<EOF

Next:
  cd $REPO && git pull
  ./install.sh -p default

The installer will back up whatever it replaces into ~/.dotfiles-backup/<timestamp>/.
EOF
fi
