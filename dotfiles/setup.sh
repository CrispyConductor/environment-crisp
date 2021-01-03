#!/bin/bash

# find directory names
DOTFILES="$(realpath "$(dirname "$0")")"
if [ "$HOME" = "" ] || [ ! -d "$HOME" ]; then echo '$HOME does not exist'; exit 1; fi
BACKUP="${HOME}/.dotfiles_backup"

# set up backup dir
if [ -e "$BACKUP" ]; then
	OLDBACKUP="${HOME}/.dotfiles_backup_old"
	mv "$BACKUP" "$OLDBACKUP"
	mkdir -p "$BACKUP"
	mv "$OLDBACKUP" "$BACKUP"
else
	mkdir -p "$BACKUP"
fi

# function to install a link to a dotfile
function install_dotfile {
	# source is relative to $DOTFILES
	SOURCE="$1"
	SOURCEABS="${DOTFILES}/${SOURCE}"
	# dest is relative to $HOME
	DEST="$2"
	DESTABS="${HOME}/${DEST}"
	echo "installing dotfile $SOURCEABS into $DESTABS"
	if [ -e "$DESTABS" ]; then
		mv "$DESTABS" "$BACKUP"
	fi
	DESTDIR="$(dirname "$DESTABS")"
	mkdir -p "$DESTDIR"
	ln -sf "$SOURCEABS" "$DESTABS"
}

# install dotfiles
install_dotfile tmux.conf .tmux.conf
install_dotfile nvim .config/nvim
install_dotfile bashrc-env .bashrc-env
install_dotfile gitconfig .gitconfig

# append bashrc-env include to bashrc
if [ ! -f ~/.bashrc ]; then touch ~/.bashrc; fi
if ! `grep bashrc-env ~/.bashrc >/dev/null`; then
	echo 'source ~/.bashrc-env' >> ~/.bashrc
fi

# append bashrc-local include to bashrc
if [ ! -f ~/.bashrc-local ]; then touch ~/.bashrc-local; fi
if ! `grep bashrc-local ~/.bashrc >/dev/null`; then
	echo 'source ~/.bashrc-local' >> ~/.bashrc
fi



