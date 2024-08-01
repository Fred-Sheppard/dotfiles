#!/usr/bin/env bash

# Exit on any error
set -e

# apt commands
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install -y $(cat apt-requirements.txt)

# neovim
if ! command -v nvim >/dev/null 2>&1; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf nvim-linux64.tar.gz
    # Path is handled in zshrc
fi

# Install cargo binstall
curl -L --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
# Install other rust apps using cargo binstall
cp cargo-env $HOME/.cargo/env
source $HOME/.cargo/env
echo '. "$HOME/.cargo/env"' >> $HOME/.zshenv

if ! command -v cargo-binstall >/dev/null 2>&1; then
  echo "Error: cargo-binstall not found. Likely an issue with \$PATH"
  exit 1
fi
cargo-binstall --no-confirm $(cat cargo-requirements.txt)

# Link to dotfiles
ln -fs $HOME/dotfiles/.zshrc $HOME/.zshrc
mkdir -p $HOME/.config/nvim
ln -fs $HOME/dotfiles/init.lua $HOME/.config/nvim/init.lua
mkdir -p $HOME/.config/zellij/layouts
mkdir -p $HOME/.local/share/zellij/
ln -fs $HOME/dotfiles/status.kdl $HOME/.config/zellij/layouts/default.kdl
ln -fs $HOME/dotfiles/starship.toml $HOME/.config/starship.toml

# Bat theme
if ! command -v bat >/dev/null 2>&1; then
    bat_config=$(bat --config-dir)
    mkdir -p "$bat_config/themes"
    wget -P "$bat_config/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
    bat cache --build
    echo '--theme="Catppuccin Mocha"' >> "$bat_config/config"
else
    echo "Bat not installed, skipping themes"
fi

# Oh My Zsh!
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# zsh-vi-mode
git clone https://github.com/jeffreytse/zsh-vi-mode $HOME/.oh-my-zsh/custom/plugins/zsh-vi-mode

# If rust commands were not successful, then we shouldn't override cat, ls etc.
if ! command -v bat >/dev/null 2>&1; then
    mv ~/.zshrc.pre-oh-my-zsh ~/.zshrc
fi
