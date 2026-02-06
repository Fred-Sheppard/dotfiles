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
