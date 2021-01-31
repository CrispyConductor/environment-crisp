#!/bin/bash

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

echo "Installing vimplug for neovim ..."
mkdir -p ~/.local/share/nvim
rm -f ~/.local/share/nvim/site/autoload/plug.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Installing vundle for neovim ..."
mkdir -p ~/.local/share/nvim/bundle
rm -rf ~/.local/share/nvim/bundle/Vundle.vim
git clone https://github.com/VundleVim/Vundle.vim.git ~/.local/share/nvim/bundle/Vundle.vim

echo "Installing tpm for tmux ..."
mkdir -p ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Installing Oh My Zsh ..."
export RUNZSH=no
if [ -d ~/.oh-my-zsh ]; then
	rm -rf ~/.oh-my-zsh-bak
	mv ~/.oh-my-zsh ~/.oh-my-zsh-bak
fi
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Setting up dotfiles ..."
./dotfiles/setup.sh

echo "Setting up clipboard ..."
./clipboard/setup.sh

echo "Installing fzf ..."
rm -rf ~/.fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc

echo "Switching out personal forks ..."
cd ~/.oh-my-zsh
#git remote add crispy git@github.com:crispy1989/ohmyzsh.git
git remote add crispy https://github.com/crispy1989/ohmyzsh.git &>/dev/null
git fetch crispy
git checkout crispy/master
cd ~/.local/share/nvim/plugged/far.vim
#git remote add crispy git@github.com:crispy1989/far.vim.git
git remote add crispy https://github.com/crispy1989/far.vim.git &>/dev/null
git fetch crispy
git checkout crispy/master
cd "$MYDIR"


