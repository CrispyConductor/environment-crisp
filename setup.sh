#!/bin/bash

force=0

ENVDIR="${HOME}/.userenv"

MYDIR="$(realpath "$(dirname "$0")")"
cd "$MYDIR"

echo "Installing python packages ..."
python3 -m pip install pynvim
if [ $? -ne 0 ]; then exit 1; fi

echo "Linking environment dir ..."
rm -f "$ENVDIR"
ln -sf "$MYDIR" "$ENVDIR"
cd "$ENVDIR"

switch_git_fork() {
	gitdir="$1"
	repourl="$2"
	branchname="$3"
	remotename="$4"
	cwd="`pwd`"
	if ! echo "$repourl" | grep / >/dev/null; then
		repourl="https://github.com/crispy1989/${repourl}.git"
	fi
	if [[ -z "$remotename" ]]; then
		remotename=crispy
	fi
	cd "$gitdir"
	if ! git remote | grep -F "$remotename" >/dev/null; then
		echo "Switching out fork for $2 ..."
		git remote add "$remotename" "$repourl"
		git fetch "$remotename"
		git checkout "$remotename"/"$branchname"
	fi
	cd "$cwd"
}

if [[ ! -e ~/.local/share/nvim/site/autoload/plug.vim ]] || [[ $force -eq 1 ]]; then
	echo "Installing vimplug for neovim ..."
	mkdir -p ~/.local/share/nvim
	rm -f ~/.local/share/nvim/site/autoload/plug.vim
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if [[ ! -e ~/.local/share/nvim/bundle/Vundle.vim ]] || [[ $force -eq 1 ]]; then
	echo "Installing vundle for neovim ..."
	mkdir -p ~/.local/share/nvim/bundle
	rm -rf ~/.local/share/nvim/bundle/Vundle.vim
	git clone https://github.com/VundleVim/Vundle.vim.git ~/.local/share/nvim/bundle/Vundle.vim
fi

if [[ ! -e ~/.tmux/plugins/tpm ]] || [[ $force -eq 1 ]]; then
	echo "Installing tpm for tmux ..."
	mkdir -p ~/.tmux/plugins
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

if [[ ! -e ~/.oh-my-zsh ]] || [[ $force -eq 1 ]]; then
	echo "Installing Oh My Zsh ..."
	export RUNZSH=no
	if [ -d ~/.oh-my-zsh ]; then
		rm -rf ~/.oh-my-zsh-bak
		mv ~/.oh-my-zsh ~/.oh-my-zsh-bak
	fi
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "Setting up dotfiles ..."
./dotfiles/setup.sh

echo "Setting up clipboard ..."
./clipboard/setup.sh

if [[ ! -e ~/.fzf ]] || [[ $force -eq 1 ]]; then
	echo "Installing fzf ..."
	rm -rf ~/.fzf
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install --key-bindings --completion --no-update-rc
fi

echo "Switching out personal forks ..."
switch_git_fork ~/.oh-my-zsh ohmyzsh master
switch_git_fork ~/.local/share/nvim/plugged/far.vim far.vim master


