# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git zsh-vi-mode)

source $ZSH/oh-my-zsh.sh

path+=("/opt/nvim-linux64/bin")

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

# ALIASES
alias vim=nvim
alias zrc='nvim ~/.zshrc'
alias cat="bat"
alias ls="eza"
alias tl="tldr"
# Coloured help pages
alias -g -- -h='-h 2>&1 | bat --language=help --style=plain --paging=always'
alias -g -- --help='--help 2>&1 | bat --language=help --style=plain --paging=always'

tldr-less() {
  if [ $# -eq 0 ]; then
    echo "Usage: tldr-less <command>"
    return 1
  fi

  tldr "$1" --color=always | bat --paging=always --style=plain
}
alias tl="tldr-less"

# FUNCTIONS
n ()
{
    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }
    # cd on quit
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    command nnn "$@"
    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f -- "$NNN_TMPFILE" > /dev/null
    }
}

# EVALS
eval "$(zoxide init zsh --cmd cd)"
eval "$(zellij setup --generate-auto-start zsh)"
