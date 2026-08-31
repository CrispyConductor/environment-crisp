# Google Chrome stable, from Google's own apt repository.
#
# Not a PPA: Chrome is published from dl.google.com, not Launchpad, so
# add-apt-repository does not apply.
#
# Why this is a hook rather than the usual repos/*.repo + packages pair.
# google-chrome-stable manages its own apt sources in its postinst, and writes
# a deb822 file:
#
#     GPG_FILE="/usr/share/keyrings/google-chrome.gpg"
#     SOURCES_FILE="/etc/apt/sources.list.d/google-chrome.sources"
#
# The repos/*.repo mechanism can only write a one-line `deb ...` list, and
# create_sources_lists() in the postinst writes its .sources file WITHOUT
# removing any legacy .list. So a one-line list from this repo would survive
# alongside Google's .sources and apt would warn about the same source being
# configured twice, on every update, forever.
#
# Writing Google's own .sources path with Google's own content avoids that
# entirely: before the package exists this file is what makes it installable,
# and afterwards the postinst simply recreates the same path with byte-identical
# content. One source file, no duplicates, and re-running this module changes
# nothing.
#
# The content below is copied from gen_sources_content() in the 152.0.7977.64-1
# postinst, including the URI - note it is chrome-stable/deb/, not the
# chrome/deb/ used by the older one-line REPOCONFIG. Both serve
# google-chrome-stable (verified 2026-08-19); matching the package avoids churn.

[ "${DO_PACKAGES:-1}" = 1 ] || return 0

CHROME_KEYRING=/usr/share/keyrings/google-chrome.gpg
CHROME_SOURCES=/etc/apt/sources.list.d/google-chrome.sources

if [ ! -s "$CHROME_KEYRING" ]; then
	info 'installing the Google Chrome signing key'
	if [ "${DRY_RUN:-0}" = 1 ]; then
		step "would install keyring $CHROME_KEYRING"
	else
		tmpkey="$(mktemp)"
		wget -qO- https://dl.google.com/linux/linux_signing_key.pub >"$tmpkey" \
			|| { rm -f "$tmpkey"; die 'failed to fetch the Google Chrome signing key'; }
		# Plain redirect, not tee -a: appending would grow the keyring on re-runs.
		gpg --dearmor <"$tmpkey" | $SUDO tee "$CHROME_KEYRING" >/dev/null
		$SUDO chmod 644 "$CHROME_KEYRING"
		rm -f "$tmpkey"
		step "installed keyring $CHROME_KEYRING"
	fi
	APT_NEEDS_UPDATE=1
else
	verbose 'Google Chrome signing key already installed'
fi

if [ ! -f "$CHROME_SOURCES" ]; then
	info 'adding the Google Chrome apt repository'
	if [ "${DRY_RUN:-0}" = 1 ]; then
		step "would write $CHROME_SOURCES"
	else
		$SUDO tee "$CHROME_SOURCES" >/dev/null <<SOURCES
### THIS FILE IS AUTOMATICALLY CONFIGURED ###
# Changes to this file will not be preserved.
# This file will not be recreated if removed.
X-Repolib-Name: Google Chrome
Types: deb
URIs: https://dl.google.com/linux/chrome-stable/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: $CHROME_KEYRING
SOURCES
		$SUDO chmod 644 "$CHROME_SOURCES"
		step "wrote $CHROME_SOURCES"
	fi
	APT_NEEDS_UPDATE=1
else
	verbose 'Google Chrome apt repository already present'
fi

if apt_pkg_installed google-chrome-stable; then
	verbose 'google-chrome-stable already installed'
else
	apt_update
	info 'installing google-chrome-stable'
	run $SUDO apt-get install -y google-chrome-stable
fi
