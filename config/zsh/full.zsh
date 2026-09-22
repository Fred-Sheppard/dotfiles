# Long-term devices: macOS, WSL, Linux, devcontainers.
# OS differences are a handful of one-liners below, not separate files —
# if a machine needs more than a line or two, fix the machine, not this file.

ZSH_DIR="${${(%):-%x}:A:h}"

NVM_DIR="$HOME/.nvm"
NVM_SCRIPT=""
NVM_COMPLETION=""

case "$(uname)" in
Darwin)
  alias battery="pmset -g batt"
  NVM_SCRIPT="/opt/homebrew/opt/nvm/nvm.sh"
  NVM_COMPLETION="/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
  ;;
Linux)
  if grep -qi microsoft /proc/version 2>/dev/null; then
    alias open="explorer.exe"
    alias copy="clip.exe"
  else
    alias rm="trash-put"
    alias battery="acpi"
  fi
  NVM_SCRIPT="/usr/share/nvm/init-nvm.sh"
  ;;
esac

# Docker Desktop CLI completions + nvm's default-node bin dir must be on
# fpath/path *before* compinit runs (inside common.zsh), so this file
# sources common.zsh itself rather than being sourced by it.
fpath=("$HOME/.docker/completions" $fpath)
if [ -d "$NVM_DIR/versions/node" ]; then
  NODE_VERSION_DIR="$NVM_DIR/versions/node"
  if [ -f "$NVM_DIR/alias/default" ]; then
    DEFAULT_NODE=$(cat "$NVM_DIR/alias/default")
  else
    DEFAULT_NODE=$(command ls -1 "$NODE_VERSION_DIR" | sort -V | tail -n 1)
  fi
  path=("$NODE_VERSION_DIR/$DEFAULT_NODE/bin" $path)
fi

path=(~/bin ~/.cargo/bin $path)
fpath=(~/.completions $fpath)

source "$ZSH_DIR/common.zsh"

# ============================================
# LAZY-LOADED NVM
# ============================================
for zb_cmd in nvm node npm npx; do
  eval "
  $zb_cmd() {
    unset -f nvm node npm npx
    [ -s \"\$NVM_SCRIPT\" ] && \\. \"\$NVM_SCRIPT\"
    [ -n \"\$NVM_COMPLETION\" ] && [ -s \"\$NVM_COMPLETION\" ] && \\. \"\$NVM_COMPLETION\"
    $zb_cmd \"\$@\"
  }
  "
done
unset zb_cmd

# ============================================
# EXPORTS
# ============================================
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="Catppuccin Mocha"
export HOMEBREW_NO_ENV_HINTS="true"

# ============================================
# ALIASES
# ============================================
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=never'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=never'
alias zrc='nvim ~/.zshrc'
alias cat="bat"
alias ls="eza"
alias mkvenv="python3 -m venv .venv"
alias vv="source .venv/bin/activate"
alias zz="exec zsh"
alias tl="tldr-less"

# ============================================
# FUNCTIONS
# ============================================
tldr-less() {
  if [ $# -eq 0 ]; then
    echo "Usage: tldr-less <command>"
    return 1
  fi
  tldr "$1" --color=always | bat --paging=always --style=plain
}

y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

dcup() {
  if [ $# -eq 0 ]; then
    echo "Usage: dcup <file>"
    return 1
  fi
  docker-compose -f "$1" up -d
}

dcdown() {
  if [ $# -eq 0 ]; then
    echo "Usage: dcdown <file>"
    return 1
  fi
  docker-compose -f "$1" down
}

# ============================================
# GIT FUNCTIONS
# ============================================
source "$ZSH_DIR/vendor/omz-git/git.plugin.zsh"

git-switch() {
  local current=$(git branch --show-current)
  if [[ "$current" == */dev ]]; then
    git switch -C "${current%/dev}/push"
  elif [[ "$current" == */push ]]; then
    git switch "${current%/push}/dev"
  else
    echo "Error: current branch '$current' must end with /dev or /push" >&2
    return 1
  fi
}

git-dopush() {
  local current=$(git branch --show-current)
  if [[ "$current" != */push ]]; then
    echo "Error: current branch '$current' does not end with /push" >&2
    return 1
  fi
  local dev_branch="${current%/push}/dev"
  if ! git show-ref --verify --quiet "refs/heads/$dev_branch"; then
    echo "Error: dev branch '$dev_branch' does not exist" >&2
    return 1
  fi
  local upstream="${current%/push}"
  git push --force-with-lease --set-upstream origin "$current:$upstream" && git switch "$dev_branch"
}

_git_rebase_check_empty() {
  local errfile=$(mktemp)
  git rebase -i "$@" 2>"$errfile"
  local exit_code=$?
  /bin/cat "$errfile" >&2
  local is_empty=0
  grep -q "nothing to do" "$errfile" && is_empty=1
  rm -f "$errfile"
  [[ $exit_code -ne 0 && $is_empty -eq 1 ]] && return 2
  return $exit_code
}

git-ship() {
  local current=$(git branch --show-current)
  local push=0
  for arg in "$@"; do
    case "$arg" in
    --push) push=1 ;;
    *)
      echo "Unknown argument: $arg" >&2
      return 1
      ;;
    esac
  done
  if [[ "$current" != */dev ]]; then
    echo "Error: current branch '$current' does not end with /dev" >&2
    return 1
  fi

  git-switch || return 1

  _git_rebase_check_empty main --autosquash
  local rebase_exit=$?

  if [[ $rebase_exit -eq 2 ]]; then
    echo "Rebase aborted (empty todo). Returning to '$current'." >&2
    git checkout "$current"
    return 1
  elif [[ $rebase_exit -ne 0 ]]; then
    return $rebase_exit
  fi

  [[ $push -eq 1 ]] && git-dopush
}

recent_branches() {
  git reflog --pretty='%gs' |
    grep -E 'checkout: moving from|branch: Created from' |
    awk '
        /checkout: moving from/ { print $NF }
        /branch: Created from/ { print $1 }
      ' |
    awk '!seen[$0]++'
}
alias gb=recent_branches

checkout_recent_branch() {
  local branch
  branch=$(recent_branches | fzf --no-multi --prompt="Recent branches: ") || return
  git checkout "$branch"
}
alias gbb=checkout_recent_branch

# ============================================
# ZELLIJ
# ============================================
zr() { zellij run --name "$*" -- zsh -ic "$*"; }
zrf() { zellij run --name "$*" --floating -- zsh -ic "$*"; }
zri() { zellij run --name "$*" --in-place -- zsh -ic "$*"; }
ze() { zellij edit "$*"; }
zef() { zellij edit --floating "$*"; }
zei() { zellij edit --in-place "$*"; }
zpipe() {
  if [ -z "$1" ]; then
    zellij pipe
  else
    zellij pipe -p "$1"
  fi
}

# ============================================
# TOOL INITIALIZATIONS
# ============================================
eval "$(zoxide init zsh --cmd cd)"

if [[ "$TERM_PROGRAM" != "vscode" ]]; then
  eval "$(starship init zsh)"
fi

# ============================================
# DEVICE OVERRIDES
# (sourced before ZELLIJ AUTO-ATTACH below, so a device can redefine
# rellij() itself - e.g. a machine without the rellij-compatible zellij
# fork can swap in plain `zellij attach` or `zellij setup
# --generate-auto-start`. Tracked in config/zsh/devices/ - one file per
# machine. A device opts in by symlinking itself:
#   ln -sfn ~/dotfiles/config/zsh/devices/<name>.zsh ~/.zshrc.local
# No auto-detection, no naming scheme beyond that.)
# ============================================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# ============================================
# ZELLIJ AUTO-ATTACH
# (rellij takes over the terminal: it either attaches to an existing
# session, or exits leaving no session started - it never creates one.
# Either way it's a foreground command, not a hook, so it must run last,
# after everything above that a returned-to (or never-attached) shell
# needs already works - prompt, vi-mode, path. Guarded against
# non-interactive sourcing (e.g. a tool probing .zshrc for env vars)
# and IDE-embedded terminals, where taking over stdin would hang or
# fight the IDE's own terminal integration.)
# ============================================
if [[ -o interactive && -z "$VSCODE_INJECTION" && "$TERM_PROGRAM" != "vscode" &&
  "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" && -z "$INTELLIJ_ENVIRONMENT_READER" ]]; then
  rellij
fi

