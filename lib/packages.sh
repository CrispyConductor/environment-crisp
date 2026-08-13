# Package installation for the module installer.
#
# A module declares packages in a `packages` file (one name per line, `#`
# comments and blank lines ignored) and apt repositories as `repos/*.repo`.
#
# Packages are gathered across every module being installed and handed to the
# package manager in one transaction, so repositories are all in place before
# anything is fetched.
#
# `packages.subst` lets a module rewrite a name it inherits from a shared
# module, which is how per-release package renames are handled without
# duplicating the shared list:
#
#   regolith-session-flashback = regolith-session-sway
#
# Sourced by install.sh.

PKG_LIST=()
PKG_SUBST_FROM=()
PKG_SUBST_TO=()
REPO_FILES=()
PKG_MANAGER=''

pkg_init() {
	if [ "$(id -u)" = 0 ]; then
		SUDO=''
	elif have_cmd sudo; then
		SUDO='sudo'
	else
		SUDO=''
	fi
}

# read_list <file> - print meaningful lines from a list file.
read_list() {
	[ -f "$1" ] || return 0
	sed -e 's/#.*$//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' "$1" | grep -v '^$' || true
}

# pkg_collect <module_dir> - accumulate packages, substitutions and repos.
pkg_collect() {
	local dir="$1" line from to

	while IFS= read -r line; do
		PKG_LIST+=("$line")
	done < <(read_list "$dir/packages")

	while IFS= read -r line; do
		from="${line%%=*}"
		to="${line#*=}"
		# Trim surrounding whitespace around the '='.
		from="${from%"${from##*[![:space:]]}"}"
		to="${to#"${to%%[![:space:]]*}"}"
		[ -n "$from" ] && [ -n "$to" ] || continue
		PKG_SUBST_FROM+=("$from")
		PKG_SUBST_TO+=("$to")
	done < <(read_list "$dir/packages.subst")

	if [ -d "$dir/repos" ]; then
		local f
		for f in "$dir"/repos/*.repo; do
			[ -f "$f" ] || continue
			REPO_FILES+=("$f")
		done
	fi

	# Package manager, if the module declares one.
	if [ -n "${MODULE_PKGMGR:-}" ]; then
		if [ -n "$PKG_MANAGER" ] && [ "$PKG_MANAGER" != "$MODULE_PKGMGR" ]; then
			die "conflicting package managers requested: $PKG_MANAGER and $MODULE_PKGMGR"
		fi
		PKG_MANAGER="$MODULE_PKGMGR"
	fi
}

# pkg_apply_subst - rewrite names, then de-duplicate while keeping order.
pkg_apply_subst() {
	local -a out=()
	local p existing i seen

	[ "${#PKG_LIST[@]}" -gt 0 ] || return 0

	for p in ${PKG_LIST[@]+"${PKG_LIST[@]}"}; do
		i=0
		while [ "$i" -lt "${#PKG_SUBST_FROM[@]}" ]; do
			if [ "$p" = "${PKG_SUBST_FROM[$i]}" ]; then
				verbose "substituting package $p -> ${PKG_SUBST_TO[$i]}"
				p="${PKG_SUBST_TO[$i]}"
				break
			fi
			i=$((i + 1))
		done
		seen=0
		for existing in ${out[@]+"${out[@]}"}; do
			if [ "$existing" = "$p" ]; then
				seen=1
				break
			fi
		done
		if [ "$seen" = 0 ]; then
			out+=("$p")
		fi
	done

	PKG_LIST=("${out[@]}")
}

# --- apt ------------------------------------------------------------------

apt_repo_install() {
	local file="$1"
	local key_url='' keyring='' entry='' list_path='' sources_url='' sources_path='' name=''
	local k v line

	name="$(basename "$file" .repo)"

	while IFS= read -r line; do
		case "$line" in ''|\#*) continue ;; esac
		k="${line%%=*}"
		v="${line#*=}"
		case "$k" in
			key_url)      key_url="$v" ;;
			keyring)      keyring="$v" ;;
			entry)        entry="$v" ;;
			list_path)    list_path="$v" ;;
			sources_url)  sources_url="$v" ;;
			sources_path) sources_path="$v" ;;
			*) warn "$file: unknown key '$k'" ;;
		esac
	done <"$file"

	info "apt repository: $name"

	if [ -n "$key_url" ] && [ -n "$keyring" ]; then
		if [ "${DRY_RUN:-0}" = 1 ]; then
			printf '  %swould install keyring%s %s (from %s)\n' \
				"$C_DIM" "$C_RESET" "$keyring" "$key_url"
		else
			local tmpkey
			tmpkey="$(mktemp)"
			wget -qO- "$key_url" >"$tmpkey" \
				|| { rm -f "$tmpkey"; die "failed to fetch repository key for $name from $key_url"; }
			# Note the plain redirect rather than `tee -a`: appending is what
			# made the old scripts grow this keyring without bound on re-runs.
			gpg --dearmor <"$tmpkey" | $SUDO tee "$keyring" >/dev/null
			$SUDO chmod 644 "$keyring"
			rm -f "$tmpkey"
			step "installed keyring $keyring"
		fi
	fi

	# Substitute {keyring} in an inline entry.
	entry="${entry//\{keyring\}/$keyring}"

	if [ -n "$entry" ] && [ -n "$list_path" ]; then
		if [ "${DRY_RUN:-0}" = 1 ]; then
			printf '  %swould write%s %s\n' "$C_DIM" "$C_RESET" "$list_path"
		else
			printf '%s\n' "$entry" | $SUDO tee "$list_path" >/dev/null
		fi
		step "wrote $list_path"
	fi

	if [ -n "$sources_url" ] && [ -n "$sources_path" ]; then
		if [ "${DRY_RUN:-0}" = 1 ]; then
			printf '  %swould download%s %s -> %s\n' "$C_DIM" "$C_RESET" "$sources_url" "$sources_path"
		else
			local tmpsrc
			tmpsrc="$(mktemp)"
			wget -qO "$tmpsrc" "$sources_url" || die "failed to fetch $sources_url"
			$SUDO install -m 644 "$tmpsrc" "$sources_path"
			rm -f "$tmpsrc"
		fi
		step "wrote $sources_path"
	fi

	APT_NEEDS_UPDATE=1
}

apt_pkg_installed() {
	dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

apt_install_packages() {
	local -a missing=()
	local p

	for p in ${PKG_LIST[@]+"${PKG_LIST[@]}"}; do
		apt_pkg_installed "$p" || missing+=("$p")
	done

	if [ "${#missing[@]}" -eq 0 ]; then
		good 'all apt packages already installed'
		return 0
	fi

	info "installing ${#missing[@]} apt package(s)"
	step "${missing[*]}"
	run $SUDO apt-get install -y "${missing[@]}"
}

apt_update() {
	[ "${APT_NEEDS_UPDATE:-0}" = 1 ] || return 0
	info 'updating apt package lists'
	run $SUDO apt-get update
	APT_NEEDS_UPDATE=0
}

# install_deb_url <display-name> <url> <package-name>
# Fetch and install a .deb, but only when the package is not already present.
# The old scripts re-downloaded Discord (~100MB) on every single run.
install_deb_url() {
	local name="$1" url="$2" pkg="$3"

	if apt_pkg_installed "$pkg"; then
		good "$name already installed"
		return 0
	fi

	local dest="$TARGET_HOME/Downloads/$pkg.deb"
	info "installing $name from $url"
	run mkdir -p "$TARGET_HOME/Downloads"
	run wget -O "$dest" "$url"
	if have_cmd gdebi; then
		run $SUDO gdebi -n "$dest"
	else
		run $SUDO apt-get install -y "$dest"
	fi
}

# --- homebrew -------------------------------------------------------------

brew_install_packages() {
	have_cmd brew || die 'brew not found; install Homebrew first (see doc/macos-setup.md)'

	local -a missing=()
	local p
	for p in ${PKG_LIST[@]+"${PKG_LIST[@]}"}; do
		brew list --formula "$p" >/dev/null 2>&1 || missing+=("$p")
	done

	if [ "${#missing[@]}" -eq 0 ]; then
		good 'all brew packages already installed'
		return 0
	fi

	info "installing ${#missing[@]} brew package(s)"
	step "${missing[*]}"
	run brew install "${missing[@]}"
}

# --- driver ---------------------------------------------------------------

pkg_install_all() {
	if [ "${#PKG_LIST[@]}" -eq 0 ] && [ "${#REPO_FILES[@]}" -eq 0 ]; then
		return 0
	fi

	local mgr="${PKG_MANAGER:-apt}"

	case "$mgr" in
		apt)
			have_cmd apt-get || die 'apt-get not found but apt packages were requested'
			local f
			for f in ${REPO_FILES[@]+"${REPO_FILES[@]}"}; do
				apt_repo_install "$f"
			done
			apt_update
			pkg_apply_subst
			apt_install_packages
			;;
		brew)
			pkg_apply_subst
			brew_install_packages
			;;
		none)
			verbose 'package installation disabled for these modules'
			;;
		*)
			die "unknown package manager: $mgr"
			;;
	esac
}
