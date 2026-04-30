#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
fail() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}
command_exists() { command -v "$1" >/dev/null 2>&1; }

#######################################
# System packages
#######################################
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y $(xargs <apt-requirements.txt)

#######################################
# Rust (rustup)
#######################################
if ! command_exists cargo; then
  log "Installing Rust via rustup"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
    sh -s -- -y --no-modify-path
fi

export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export PATH="$CARGO_HOME/bin:$PATH"

command_exists cargo || fail "Rust installation failed"

#######################################
# cargo-binstall
#######################################
if ! command_exists cargo-binstall; then
  log "Installing cargo-binstall"
  curl -L --proto '=https' --tlsv1.2 -sSf \
    https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh |
    bash
fi

command_exists cargo-binstall || fail "cargo-binstall not found"

cargo-binstall --no-confirm $(xargs <cargo-requirements.txt)

#######################################
# Neovim (bob)
#######################################
bob use stable

#######################################
# Dotfiles
#######################################
ln -sfn "$HOME/dotfiles/.zshrc" "$HOME/.zshrc"
mkdir -p "$HOME/.config/zellij/layouts"
mkdir -p "$HOME/.local/share/zellij"
ln -sfn "$HOME/dotfiles/status.kdl" \
  "$HOME/.config/zellij/layouts/default.kdl"
ln -sfn "$HOME/dotfiles/starship.toml" \
  "$HOME/.config/starship.toml"

#######################################
# Bat theme
#######################################
if command_exists bat; then
  BAT_CONFIG_DIR="$(bat --config-dir)"
  mkdir -p "$BAT_CONFIG_DIR/themes"
  wget -q -O "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" \
    https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
  bat cache --build
  grep -q Catppuccin "$BAT_CONFIG_DIR/config" 2>/dev/null ||
    echo '--theme="Catppuccin Mocha"' >>"$BAT_CONFIG_DIR/config"
fi

#######################################
# Zellij & Rellij
#######################################
ZELLIJ_FORK_REPO="Fred-Sheppard/zellij"
ZELLIJ_FORK_BINARY_PREFIX="zellij"
ZELLIJ_FORK_BINARY_SUFFIX="x86_64-linux"

# Get the latest release tag (e.g. "v0.44.1-rellij")
ZELLIJ_FORK_TAG=$(curl -s "https://api.github.com/repos/${ZELLIJ_FORK_REPO}/releases/latest" |
  grep '"tag_name"' |
  head -1 |
  sed 's/.*"tag_name": *"\(.*\)".*/\1/')

# Build the filename and URL
ZELLIJ_FORK_FILENAME="${ZELLIJ_FORK_BINARY_PREFIX}-${ZELLIJ_FORK_TAG}-${ZELLIJ_FORK_BINARY_SUFFIX}"
ZELLIJ_FORK_URL="https://github.com/${ZELLIJ_FORK_REPO}/releases/download/${ZELLIJ_FORK_TAG}/${ZELLIJ_FORK_FILENAME}"

BIN_DIR="$HOME/.cargo/bin"

wget -q -P $BIN_DIR $ZELLIJ_FORK_URL

ZELLIJ_FORK_FILE="$BIN_DIR/$ZELLIJ_FORK_FILENAME"
chmod +x "$ZELLIJ_FORK_FILE"

# Backup existing zellij if it exists (file or symlink)
ZELLIJ_FORK_TARGET="$BIN_DIR/zellij"
if [ -e "$ZELLIJ_FORK_TARGET" ] || [ -L "$ZELLIJ_FORK_TARGET" ]; then
  log "Backing up $ZELLIJ_FORK_TARGET to $BIN_DIR/zellij.bak"
  mv -f "$ZELLIJ_FORK_TARGET" "$BIN_DIR/zellij.bak"
fi

# Create symlink to new binary
ln -s "$ZELLIJ_FORK_FILE" "$ZELLIJ_FORK_TARGET"

#######################################
# Oh My Zsh
#######################################
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/jeffreytse/zsh-vi-mode \
  "$ZSH_CUSTOM/plugins/zsh-vi-mode" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" 2>/dev/null || true
git clone https://github.com/zsh-users/zsh-history-substring-search.git \
  "$ZSH_CUSTOM/plugins/zsh-history-substring-search"

#######################################
# NVM + Node (LTS)
#######################################
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

#######################################
# win32yank (WSL)
#######################################
if grep -qi microsoft /proc/version && ! command_exists win32yank.exe; then
  TMP="$(mktemp -d)"
  wget -q -O "$TMP/win32yank.zip" \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -q "$TMP/win32yank.zip" -d "$TMP"
  sudo mv "$TMP/win32yank.exe" /usr/local/bin/
  sudo chmod +x /usr/local/bin/win32yank.exe
  rm -rf "$TMP"
fi

log "Setup complete 🚀 Restart your shell."
log "Next steps:"
log "Install a NerdFont"
