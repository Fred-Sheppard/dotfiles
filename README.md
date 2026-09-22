# dotfiles

A collection of my machine's configuration files.

Zsh has two configs (`config/zsh/full.zsh` and `config/zsh/minimal.zsh`),
sharing `config/zsh/common.zsh` for plugins/keybindings so both behave
identically. See `config/zsh/common.zsh` for details.

## Long-term devices (macOS, WSL, Linux, devcontainers)

Prerequisites: win32yank must be on your PATH (WSL only, installed by the script below).

```bash
git submodule update --init --recursive
cd install
bash install.sh
```

This links `~/.zshrc` to `config/zsh/full.zsh`.

On Linux, update your system packages before running. Ubuntu/Debian is
handled automatically (`apt-get update && apt-get upgrade`); on other
distros the script skips package installation and only checks that
`curl fzf gcc git make perl unzip zsh` (plus `ca-certificates`) are
already installed, so install them with your package manager first.

Machine-specific extras (e.g. a work WSL box's internal tools) live in
`config/zsh/devices/<name>.zsh`, tracked in this repo. A device opts in
by symlinking itself - full.zsh sources `~/.zshrc.local` last, if present:

```bash
ln -sfn ~/dotfiles/config/zsh/devices/<name>.zsh ~/.zshrc.local
```

## Short-lived containers

From the host, against a running container:

```bash
bash install/setup-container.sh <container_id>:<path-in-container>
```

This installs zsh and links `.zshrc` to `config/zsh/minimal.zsh` inside the container.
