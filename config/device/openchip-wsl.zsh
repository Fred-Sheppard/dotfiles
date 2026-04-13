export PATH="/mnt/c/Users/frederick.sheppard/scoop/shims:$PATH"
alias open="explorer.exe"
alias copy="clip.exe"

# Only run zellij if not connected to JetBrains IDE or VS Code
if [[ -z "$TERMINAL_EMULATOR" && -z "$TERM_PROGRAM" ]]; then
    eval "$(zellij setup --generate-auto-start zsh)"
fi
