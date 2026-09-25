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

The binary is picked from whatever the latest release actually publishes,
matched against this machine's OS and architecture. A new platform added to
the fork's releases is picked up here with no change to this script.

Options:
  -h, --help  Show this help message and exit

EOF
}

# Parse args
while [ $# -gt 0 ]; do
  case "$1" in
  -h | --help)
    usage
    exit 0
    ;;
  *)
    fail "Unknown option: $1. Use --help for usage."
    ;;
  esac
done

OS="$(uname -s)"
ARCH="$(uname -m)"

# Asset names are matched on these tokens rather than on a hardcoded list of
# platforms, so a release that starts shipping, say, aarch64-linux just works.
# Each case lists the spellings a build might use for the same thing; anything
# unrecognised falls through to its own name, which is usually right.
case "$OS" in
Linux) OS_RE='linux' ;;
Darwin) OS_RE='macos|darwin|apple' ;;
*) OS_RE="$OS" ;;
esac

case "$ARCH" in
x86_64) ARCH_RE='x86_64|amd64|x64' ;;
arm64 | aarch64) ARCH_RE='aarch64|arm64' ;;
armv7l) ARCH_RE='armv7l|armv7|armhf' ;;
*) ARCH_RE="$ARCH" ;;
esac

REPO="Fred-Sheppard/zellij"

RELEASE="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")" ||
  fail "Failed to fetch the latest release from $REPO"

TAG=$(printf '%s\n' "$RELEASE" |
  grep '"tag_name"' |
  head -1 |
  sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

[ -z "$TAG" ] && fail "Failed to fetch latest release tag"

# Every asset's download URL, straight from the release - no URL building, so
# a change in the naming scheme doesn't need mirroring here.
ASSETS="$(printf '%s\n' "$RELEASE" |
  sed -n 's/.*"browser_download_url": *"\([^"]*\)".*/\1/p')"

[ -z "$ASSETS" ] && fail "Release $TAG publishes no assets"

# The fork reports its tag verbatim, minus the leading v:
#   $ zellij --version
#   zellij 0.44.1-rellij
if command_exists zellij; then
  # An unusable binary (wrong arch, missing libs) must not take the script
  # down with it - pipefail would otherwise abort here without printing a
  # thing. Treat it as "no version" and reinstall over the top.
  CURRENT="$(zellij --version 2>/dev/null | awk '{print $2}')" || CURRENT=""
  if [[ "$CURRENT" == "${TAG#v}" ]]; then
    log "zellij $TAG already installed at $(command -v zellij) - nothing to do"
    exit 0
  fi
fi

# Both tokens have to appear in the same asset name, each bounded by a
# separator so a fragment of the version or tag can't stand in for one.
URL="$(printf '%s\n' "$ASSETS" |
  grep -Ei "(^|[/_.-])(${ARCH_RE})([_.-]|$)" |
  grep -Ei "(^|[/_.-])(${OS_RE})([_.-]|$)" |
  head -1)" || URL=""

if [ -z "$URL" ]; then
  fail "No $OS/$ARCH binary in $TAG. That release publishes:
$(printf '%s\n' "$ASSETS" | sed 's|.*/|  |')"
fi

FILENAME="$(basename "$URL")"

BIN_DIR="$HOME/.cargo/bin"
mkdir -p "$BIN_DIR"

FILE="$BIN_DIR/$FILENAME"

# Download to a temp file and rename into place. Writing directly to $FILE
# fails with ETXTBSY (curl error 23) when that exact binary is the one
# currently running - e.g. re-running this from inside a zellij session on the
# version we are about to fetch.
TMP="$(mktemp "$BIN_DIR/.zellij.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

log "Pulling $URL..."
curl -fsSL -o "$TMP" "$URL" || fail "Download failed"

chmod +x "$TMP"
mv -f "$TMP" "$FILE"
trap - EXIT

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
