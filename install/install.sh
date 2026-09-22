#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
fail() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}
command_exists() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname)"

#######################################
# System packages
#######################################
case "$OS" in
Darwin)
  if ! command_exists brew; then
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      fail "Homebrew not found. Install it first: https://brew.sh"
    fi
  fi
  log "Updating Homebrew"
  brew update
  log "Installing bootstrap packages via Homebrew"
  brew install fzf cargo-binstall
  ;;
Linux)
  sudo apt-get update
  sudo apt-get upgrade -y
  sudo apt-get install -y fzf gcc zsh
  ;;
*)
  fail "Unsupported OS: $OS"
  ;;
esac

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
  case "$OS" in
  Darwin)
    fail "cargo-binstall not found after Homebrew install"
    ;;
  Linux)
    log "Installing cargo-binstall"
    curl -L --proto '=https' --tlsv1.2 -sSf \
      https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh |
      bash
    ;;
  esac
fi

command_exists cargo-binstall || fail "cargo-binstall not found"

cargo-binstall --no-confirm $(xargs <"$SCRIPT_DIR/tools/cargo.txt")

#######################################
# Neovim (bob)
#######################################
bob use stable

#######################################
# Dotfiles
#######################################
ln -sfn "$HOME/dotfiles/config/zsh/full.zsh" "$HOME/.zshrc"
mkdir -p "$HOME/.config/zellij/layouts"
mkdir -p "$HOME/.local/share/zellij"
ln -sfn "$HOME/dotfiles/config/zellij/layouts/status.kdl" \
  "$HOME/.config/zellij/layouts/default.kdl"
ln -sfn "$HOME/dotfiles/config/starship.toml" \
  "$HOME/.config/starship.toml"

#######################################
# Bat theme
#######################################
if command_exists bat; then
  BAT_CONFIG_DIR="$(bat --config-dir)"
  mkdir -p "$BAT_CONFIG_DIR/themes"
  curl -fsSL -o "$BAT_CONFIG_DIR/themes/Catppuccin Mocha.tmTheme" \
    https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
  bat cache --build
  grep -q Catppuccin "$BAT_CONFIG_DIR/config" 2>/dev/null ||
    echo '--theme="Catppuccin Mocha"' >>"$BAT_CONFIG_DIR/config"
fi

log "Pulling zellij fork"
case "$OS" in
Darwin) bash "$SCRIPT_DIR/pull-zellij-fork.sh" --macos ;;
Linux) bash "$SCRIPT_DIR/pull-zellij-fork.sh" --x86 ;;
esac

#######################################
# Zsh plugins (vendored as submodules)
#######################################
log "Fetching vendored zsh plugins"
git -C "$HOME/dotfiles" submodule update --init --recursive config/zsh/vendor

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
# GUI apps (Homebrew Cask)
#######################################
if [[ "$OS" == "Darwin" ]]; then
  log "Installing GUI apps via Homebrew Cask"
  # Errors if an app already exists at /Applications/*.app via a non-Homebrew
  # install - fix manually with `brew install --cask --force <name>` or by
  # removing the existing app, rather than scripting around it here.
  brew install --cask $(xargs <"$SCRIPT_DIR/brew_casks.txt")
fi

#######################################
# win32yank (WSL)
#######################################
if [[ "$OS" == "Linux" ]] && grep -qi microsoft /proc/version && ! command_exists win32yank.exe; then
  TMP="$(mktemp -d)"
  curl -fsSL -o "$TMP/win32yank.zip" \
    https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip
  unzip -q "$TMP/win32yank.zip" -d "$TMP"
  sudo mv "$TMP/win32yank.exe" /usr/local/bin/
  sudo chmod +x /usr/local/bin/win32yank.exe
  rm -rf "$TMP"
fi

log "Setup complete 🚀 Restart your shell."
log "Next steps:"
log "Install a NerdFont"
