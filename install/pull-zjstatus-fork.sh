#!/usr/bin/env bash
set -Eeuo pipefail

log() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
fail() {
  echo -e "\033[1;31m[ERROR]\033[0m $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTION]

Download the latest zjstatus plugin from Fred Sheppard's fork into
\$HOME/.config/zellij/plugins, where the status layout loads it from.

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

REPO="Fred-Sheppard/zjstatus"
URL="https://github.com/${REPO}/releases/latest/download/zjstatus.wasm"

PLUGIN_DIR="$HOME/.config/zellij/plugins"
mkdir -p "$PLUGIN_DIR"

TARGET="$PLUGIN_DIR/zjstatus.wasm"

# Rename into place so a failed download never leaves a truncated plugin behind
TMP="$(mktemp "$PLUGIN_DIR/.zjstatus.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

log "Pulling $URL..."
curl -fsSL -o "$TMP" "$URL" || fail "Download failed - has $REPO published a release?"

chmod 644 "$TMP"
mv -f "$TMP" "$TARGET"
trap - EXIT

log "Installed zjstatus at $TARGET"
