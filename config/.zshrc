export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# ============================================
# OH-MY-ZSH OPTIMIZATIONS
# ============================================

plugins=(git zsh-vi-mode rust zsh-autosuggestions zsh-syntax-highlighting safe-paste)

source $ZSH/oh-my-zsh.sh

# ============================================
# PATH & FPATH
# ============================================
path=(~/bin ~/.cargo/bin /home/fred/.local/share/bob/nvim-bin $path)
fpath=(~/.completions $fpath)

# ============================================
# ZSH-VI-MODE CONFIG
# ============================================
source /opt/homebrew/share/zsh-history-substring-search/zsh-history-substring-search.zsh

bindkey -a 'k' history-substring-search-up
bindkey -a 'j' history-substring-search-down
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

bindkey -M viins '\e.' insert-last-word
bindkey -M vicmd H beginning-of-line
bindkey -M vicmd L end-of-line

# ============================================
# EXPORTS
# ============================================
export EDITOR=nvim
export VISUAL=$EDITOR
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="Catppuccin Mocha"
export HOMEBREW_NO_ENV_HINTS="true"

# ============================================
# ALIASES
# ============================================
# Coloured help pages
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=always'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=always'
alias zrc='nvim ~/.zshrc'
alias cat="bat"
alias ls="eza"
alias mkvenv="python3 -m venv .venv"
alias vv="source .venv/bin/activate"
alias zz="exec zsh"

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
alias tl="tldr-less"

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function dcup() {
  if [ $# -eq 0 ]; then
    echo "Usage: dcup <file>"
    return 1
  fi
  docker-compose -f $1 up -d
}

function dcdown() {
  if [ $# -eq 0 ]; then
    echo "Usage: dcdown <file>"
    return 1
  fi
  docker-compose -f $1 down
}

# GIT FUNCTIONS
# Create/reset the push branch from current dev branch
git-switch() {
  local current=$(git branch --show-current)
  if [[ "$current" != */dev ]]; then
    echo "Error: current branch '$current' does not end with /dev" >&2
    return 1
  fi
  local push_branch="${current%/dev}/push"
  git switch -C "$push_branch"
}

# Push and switch back to dev branch
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
  git rebase -i "$@" 2>/tmp/git-rebase-err
  local exit_code=$?

  # Use /bin/cat instead of bat
  /bin/cat /tmp/git-rebase-err >&2

  if [[ $exit_code -ne 0 ]] && grep -q "nothing to do" /tmp/git-rebase-err; then
    return 2
  fi

  return $exit_code
}

# Full pipeline: switch → rebase → dopush
git-ship() {
  local current=$(git branch --show-current)
  local push=0
  for arg in "$@"; do
    case "$arg" in
      --push) push=1 ;;
      *) echo "Unknown argument: $arg" >&2; return 1 ;;
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

  if [[ $push -eq 1 ]]; then
    git-dopush
  fi
}

# ============================================
# ZELLIJ FUNCTIONS
# ============================================
function zr () { zellij run --name "$*" -- zsh -ic "$*";}
function zrf () { zellij run --name "$*" --floating -- zsh -ic "$*";}
function zri () { zellij run --name "$*" --in-place -- zsh -ic "$*";}
function ze () { zellij edit "$*";}
function zef () { zellij edit --floating "$*";}
function zei () { zellij edit --in-place "$*";}
function zpipe () {
  if [ -z "$1" ]; then
    zellij pipe;
  else
    zellij pipe -p $1;
  fi
}

# ============================================
# TOOL INITIALIZATIONS
# ============================================
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"
eval "$(fzf --zsh)"

# ============================================
# DEVICE-SPECIFIC CONFIG
# ============================================
[ -f ~/.zshrc-device ] && source ~/.zshrc-device
