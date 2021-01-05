#!/bin/bash

ENVDIR="${HOME}/.userenv"

MYDIR="$(realpath "$(dirname "$0")")"
cd "$MYDIR"

echo "Linking environment dir ..."
rm -f "$ENVDIR"
ln -sf "$MYDIR" "$ENVDIR"
cd "$ENVDIR"

echo "Installing vimplug for neovim ..."
rm -f ~/.local/share/nvim/site/autoload/plug.vim
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "Installing Oh My Zsh ..."
export RUNZSH=no
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Setting up dotfiles ..."
./dotfiles/setup.sh

echo "Setting up clipboard ..."
./clipboard/setup.sh

