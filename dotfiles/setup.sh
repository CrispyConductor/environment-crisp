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
# note: copy in basic tmux.conf, then setup-tmux.sh will overwrite it with a better version if it can
install_dotfile tmux-basic.conf .tmux.conf
install_dotfile nvim .config/nvim
install_dotfile shellrc-common .shellrc-common
install_dotfile bashrc-env .bashrc-env
install_dotfile zshrc .zshrc
install_dotfile gitconfig .gitconfig
install_dotfile crispy.zsh-theme .oh-my-zsh/themes/crispy.zsh-theme

# Setup the real tmux.conf
"$DOTFILES/setup-tmux.sh"
if [ $? -ne 0 ]; then
	echo 'Error setting up tmux.  Using basic config.'
fi

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

# Authorized ssh keys - do not overwrite existing
mkdir -p ~/.ssh
if [ ! -f ~/.ssh/authorized_keys ]; then
	cat "$DOTFILES/ssh_authorized_keys" > ~/.ssh/authorized_keys
fi

