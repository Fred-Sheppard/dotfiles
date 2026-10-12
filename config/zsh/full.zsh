# Long-term devices: macOS, WSL, Linux, devcontainers.

ZSH_DIR="${${(%):-%x}:A:h}"

case "$(uname)" in
Darwin)
  alias copy="pbcopy"
  alias battery="pmset -g batt"
  ;;
Linux)
  if grep -qi microsoft /proc/version 2>/dev/null; then
    alias open="explorer.exe"
    alias copy="clip.exe"
  else
    alias copy="scopy"
    alias battery="acpi"
  fi
  ;;
esac

fpath=("$HOME/.docker/completions" $fpath)

export NVM_DIR="$HOME/.nvm"
if [ -d "$NVM_DIR/versions/node" ]; then
  # Resolve nvm alias chains (default -> lts/* -> lts/jod -> v22.x)
  DEFAULT_NODE=default
  for _ in 1 2 3 4 5; do
    [ -f "$NVM_DIR/alias/$DEFAULT_NODE" ] || break
    DEFAULT_NODE=$(<"$NVM_DIR/alias/$DEFAULT_NODE")
  done
  # Aliases may be partial versions ("20") or names like "node"; fall back to the newest install
  node_dirs=("$NVM_DIR"/versions/node/v${DEFAULT_NODE#v}(|.*)(Nn/))
  (( $#node_dirs )) || node_dirs=("$NVM_DIR"/versions/node/v*(Nn/))
  (( $#node_dirs )) && path=("$node_dirs[-1]/bin" $path)
  unset DEFAULT_NODE node_dirs
fi

path=(~/bin ~/.cargo/bin ~/.local/share/bob/nvim-bin $path)
fpath=(~/.completions $fpath)

# Call after all path updates are completed, due to compinit call
source "$ZSH_DIR/common.zsh"

# ============================================
# LAZY-LOADED NVM
# ============================================
# Sourcing nvm.sh costs ~100ms, so defer it until something needs node.
for zb_cmd in nvm node npm npx; do
  eval "
  $zb_cmd() {
    unset -f nvm node npm npx
    [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"
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
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=auto'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=auto'
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

extract() {
  if [ $# -eq 0 ]; then
    echo "Usage: extract <archive>..." >&2
    return 1
  fi
  local archive
  for archive in "$@"; do
    if [ ! -f "$archive" ]; then
      echo "extract: '$archive' is not a file" >&2
      continue
    fi
    case "$archive" in
    *.tar.gz | *.tgz) tar xzvf "$archive" ;;
    *.tar.bz2 | *.tbz2) tar xjvf "$archive" ;;
    *.tar.xz | *.txz) tar xJvf "$archive" ;;
    *.tar.zst) tar --zstd -xvf "$archive" ;;
    *.tar) tar xvf "$archive" ;;
    *.gz) gunzip -k "$archive" ;;
    *.bz2) bunzip2 -k "$archive" ;;
    *.xz) unxz -k "$archive" ;;
    *.zst) unzstd "$archive" ;;
    *.zip | *.jar | *.war | *.whl) unzip "$archive" ;;
    *.7z) 7z x "$archive" ;;
    *.rar) unrar x "$archive" ;;
    *.deb) ar x "$archive" ;;
    *) echo "extract: unknown archive type '$archive'" >&2 ;;
    esac
  done
}

copypath() {
  local target="${1:-$PWD}"
  print -rn -- "${target:A}" | copy
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

# Deferred so zsh-vi-mode's lazy init doesn't clobber tv's ^R binding
# TODO: Investigate `ZVM_INIT_MODE=sourcing`
zvm_after_init_commands+=('eval "$(tv init zsh)"')

# ============================================
# DEVICE OVERRIDES
# Devices can redefine rellij() to avoid calling it
# ============================================
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# ============================================
# ZELLIJ AUTO-ATTACH
# ============================================
if [[ -o interactive && -z "$VSCODE_INJECTION" && "$TERM_PROGRAM" != "vscode" &&
  "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" && -z "$INTELLIJ_ENVIRONMENT_READER" ]]; then
  rellij
fi

