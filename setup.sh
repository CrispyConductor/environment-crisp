#!/bin/bash

MYDIR="$(readlink -e "$(dirname "$0")")"
cd "$MYDIR"

echo "Installing vimplug for neovim ..."
rm -f ~/.local/share/nvim/site/autoload/plug.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Setting up dotfiles ..."
./dotfiles/setup.sh

echo "Copying files ..."
ln -sf "${MYDIR}/cheat-sheet.txt" "${HOME}/cheat-sheet.txt"

