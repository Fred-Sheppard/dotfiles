-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.guifont = "JetBrainsMono Nerd Font:h16"
vim.opt.shiftwidth = 2
vim.opt.relativenumber = false

-- LazyVim defaults to root_spec = { "lsp", { ".git", "lua" }, "cwd" }. The LSP
-- detector prefers the longest matching path, so e.g. clangd in a C subdir
-- becomes "the project root" and Telescope greps/files stay under that tree.
-- Use process cwd only so pickers don't follow LSP / nested .git / patterns.
vim.g.root_spec = { "cwd" }
