# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-vi-mode rust zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

path=(~/bin $path)

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
bindkey -M vicmd H beginning-of-line
bindkey -M vicmd L end-of-line

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
export HOMEBREW_NO_ENV_HINTS="true"

# ALIASES
# Coloured help pages
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=always'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=always'
alias zrc='nvim ~/.zshrc'
alias cat="bat"
alias ls="eza"
alias mkvenv="python3 -m venv .venv"
alias vv="source .venv/bin/activate"
alias zz="exec zsh"

# FUNCTIONS
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


# EVALS
eval "$(zoxide init zsh --cmd cd)"
eval "$(zellij setup --generate-auto-start zsh)"
eval "$(starship init zsh)"
eval "$(fzf --zsh)"
eval "$(ngrok completion)"

 export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

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
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/fred/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions
