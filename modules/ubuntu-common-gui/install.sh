# Setup steps shared by every ubuntu<ver>-gui module.

# --- Discord --------------------------------------------------------------
#
# Not in apt, so it comes from a .deb. install_deb_url skips the download when
# the package is already present; the old scripts re-fetched ~100MB and ran an
# interactive gdebi on every single run.

if [ "${DO_PACKAGES:-1}" = 1 ]; then
	install_deb_url 'Discord' \
		'https://discordapp.com/api/download?platform=linux&format=deb' \
		'discord'
fi

# --- GUI clipboard bridge -------------------------------------------------

if have_cmd systemctl && [ "$TARGET_HOME" = "$HOME" ]; then
	info 'enabling the GUI clipboard sync service'
	run systemctl --user daemon-reload || true
	run systemctl --user enable --now uiclipsyncd.service \
		|| warn 'could not enable uiclipsyncd.service; start it by hand with libexec/clipboard/start_uiclipsyncd.sh'
else
	verbose 'skipping systemd user service (no systemctl, or installing into a different home)'
fi
