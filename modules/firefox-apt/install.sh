# Install Firefox from the mozillateam PPA instead of the snap.
#
# The snap build cannot talk to the keepassxc browser plugin, which is the
# whole reason for this module.
#
# Unlike the script this replaces, it is re-runnable: that version began with
# `sudo snap remove firefox` followed by `exit 1` on failure, so a second run
# always aborted at the first line once the snap was gone.

[ "${DO_PACKAGES:-1}" = 1 ] || return 0

if have_cmd snap && snap list firefox >/dev/null 2>&1; then
	info 'removing the Firefox snap'
	run $SUDO snap remove firefox
else
	verbose 'no Firefox snap installed'
fi

if apt_pkg_installed firefox && [ ! -f /etc/apt/preferences.d/mozilla ]; then
	info 'removing the distro Firefox package before switching to the PPA'
	run $SUDO apt-get remove -y firefox
fi

if ! grep -rqs mozillateam /etc/apt/sources.list.d/ 2>/dev/null; then
	info 'adding the mozillateam PPA'
	run $SUDO add-apt-repository -y ppa:mozillateam/ppa
	APT_NEEDS_UPDATE=1
else
	verbose 'mozillateam PPA already present'
fi

# Pin the PPA above the Ubuntu package so upgrades do not pull the snap
# transitional package back in.
if [ ! -f /etc/apt/preferences.d/mozilla ]; then
	info 'pinning firefox to the mozillateam PPA'
	if [ "${DRY_RUN:-0}" = 1 ]; then
		step 'would write /etc/apt/preferences.d/mozilla'
	else
		$SUDO tee /etc/apt/preferences.d/mozilla >/dev/null <<'PIN'
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
PIN
	fi
else
	verbose 'firefox pin already in place'
fi

apt_update
run $SUDO apt-get install -y firefox
