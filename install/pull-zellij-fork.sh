#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
fail() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}
command_exists() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Download and install the latest zellij binary from Fred Sheppard's fork.

Options:
  --x86       Install Linux x86_64 binary (default)
  --macos     Install macOS (Apple Silicon) binary (aarch64-macos)
  -h, --help  Show this help message and exit

EOF
}

# Defaults
PLATFORM="x86"

# Parse args
if [ $# -gt 1 ]; then
  fail "Too many arguments. Use --help for usage."
fi

if [ $# -eq 1 ]; then
  case "$1" in
  --x86)
    PLATFORM="x86"
    ;;
  --macos)
    PLATFORM="macos"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    fail "Unknown option: $1. Use --help for usage."
    ;;
  esac
fi

REPO="Fred-Sheppard/zellij"
BINARY_PREFIX="zellij"

case "$PLATFORM" in
x86)
  BINARY_SUFFIX="x86_64-linux"
  ;;
macos)
  BINARY_SUFFIX="aarch64-macos"
  ;;
esac

# Get latest release tag
TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" |
  grep '"tag_name"' |
  head -1 |
  sed 's/.*"tag_name": *"\(.*\)".*/\1/')

[ -z "$TAG" ] && fail "Failed to fetch latest release tag"

FILENAME="${BINARY_PREFIX}-${TAG}-${BINARY_SUFFIX}"
URL="https://github.com/${REPO}/releases/download/${TAG}/${FILENAME}"

BIN_DIR="$HOME/.cargo/bin"
mkdir -p "$BIN_DIR"

log "Pulling $URL..."
wget -q -P "$BIN_DIR" "$URL" || fail "Download failed"

FILE="$BIN_DIR/$FILENAME"
chmod +x "$FILE"

TARGET="$BIN_DIR/zellij"

# Backup existing
if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  log "Backing up existing zellij to $BIN_DIR/zellij.bak"
  mv -f "$TARGET" "$BIN_DIR/zellij.bak"
fi

# Symlink
log "Creating symlink"
ln -s "$FILE" "$TARGET"

log "Installed zellij ($TAG) at $TARGET"
