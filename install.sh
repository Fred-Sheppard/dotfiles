#!/usr/bin/env bash

# apt commands
sudo apt-get update
sudo apt-get upgrade -y
sudo apt install -y $(cat apt-requirements.txt)

# neovim
if [ ! -x nvim ]; then
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

if [ ! -x cargo-binstall ]; then
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
if [ -x bat ]; then
    mkdir -p "$(bat --config-dir)/themes"
    wget -P "$(bat --config-dir)/themes" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
    bat cache --build
else
    echo "Bat not installed, skipping themes"
fi

# Oh My Zsh!
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# zsh-vi-mode
git clone https://github.com/jeffreytse/zsh-vi-mode $HOME/.oh-my-zsh/custom/plugins/zsh-vi-mode

# If rust commands were not successful, then we shouldn't override cat, ls etc.
if [ -x bat ]; then
    mv ~/.zshrc.pre-oh-my-zsh ~/.zshrc
fi
