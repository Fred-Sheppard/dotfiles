# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

path+=("/opt/nvim-linux64/bin")
path=(~/bin/ $path)

fpath=(~/.completions $fpath)

# zsh-vim-mode
zvm_after_init_commands+=("
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey -a 'k' up-line-or-beginning-search
bindkey -a 'j' down-line-or-beginning-search
")
bindkey -M viins '\e.' insert-last-word

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
export VISUAL=$EDITOR

# EXPORTS
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export BAT_THEME="Catppuccin Mocha"
export ZELLIJ_AUTO_ATTACH="true"

# ALIASES
alias zrc='nvim ~/.zshrc'
alias cat="bat"
alias ls="eza"
alias tl="tldr"
# Coloured help pages
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=always'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=always'
alias y="yazi"

tldr-less() {
  if [ $# -eq 0 ]; then
    echo "Usage: tldr-less <command>"
    return 1
  fi

  tldr "$1" --color=always | bat --paging=always --style=plain
}
alias tl="tldr-less"

# FUNCTIONS

# yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# EVALS
eval "$(zoxide init zsh --cmd cd)"
eval "$(zellij setup --generate-auto-start zsh)"
eval "$(starship init zsh)"

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

# Added by Windsurf
export PATH="/Users/fred/.codeium/windsurf/bin:$PATH"
