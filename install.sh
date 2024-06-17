#!/usr/bin/env bash

# apt commands
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update
sudo apt-get upgrade
sudo apt install -y $(cat apt-requirements.txt)

# Oh My Zsh!
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# zsh-vi-mode
git clone https://github.com/jeffreytse/zsh-vi-mode $ZSH_CUSTOM/plugins/zsh-vi-mode

# rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
export PATH=$PATH:$HOME/cargo/bin

# Install cargo binstall
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
# Install other rust apps using cargo binstall
cargo binstall --no-confirm $(cat cargo-requirements.txt)

# Bat theme
mkdir -p "$(bat --config-dir)/themes"
wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
bat cache --build

# clone and link to dotfiles
ln -s $HOME/dotfiles/.zshrc $HOME/.zshrc
mkdir -p $HOME/.config/nvim
ln -s $HOME/dotfiles/init.lua $HOME/.config/nvim/init.lua
mkdir -p $HOME/.config/zellij/layouts
ln -s $HOME/dotfiles/status.kdl $HOME/.config/zellij/layouts/default.kdl
ln -s $HOME/dotfiles/starship.toml $HOME/.config/starship.toml
