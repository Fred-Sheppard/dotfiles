-- Clone lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- NEOVIM SETTINGS
vim.opt.clipboard = 'unnamed'
vim.opt.hlsearch = false
vim.opt.relativenumber = true
-- Disables right click, allowing for copying without xclip or similar
vim.opt.mouse=""

-- Indentation settings
vim.opt.shiftwidth = 4
vim.opt.smarttab = true
vim.opt.expandtab = true
vim.opt.tabstop = 8
vim.opt.softtabstop = 0
-- Quick scope
vim.g.qs_highlight_on_keys = { "f", "F", "t", "T" }


-- LEADER
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- PLUGINS
require('lazy').setup({
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
    {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
    'gelguy/wilder.nvim',
    'unblevable/quick-scope',
})

vim.cmd.colorscheme "catppuccin-mocha"

require('nvim-treesitter.configs').setup({
    highlight = { enable = true },
    ensure_installed = { "vimdoc", "vim", "lua"}
})

local wilder = require('wilder')
wilder.setup({modes = {':', '/', '?'}})


-- KEYMAP
local opt = {
    noremap = true,
    silent = true,
}
vim.keymap.set('n', ' ', '<Nop>', opt)
vim.keymap.set('n', '<Leader>w', ':w<CR>', opt) -- Write buffer
vim.keymap.set('n', '<Leader>x', ':x<CR>', opt) -- Write and exit
vim.keymap.set('n', '<Leader>q', ':q<CR>', opt) -- Write and exit
vim.keymap.set('n', '<Leader>a', 'ggVG', opt) -- Select all
vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opt) -- Error messages
vim.keymap.set('n', 'H', '^', opt) -- First character
vim.keymap.set('n', 'L', '$', opt) -- Last character
vim.keymap.set('n', 'nv', ':e ~/.config/nvim/init.lua<CR>', opt)
vim.keymap.set('n', 'nw', ':set wrap!<CR>', opt)
-- Swap p and P
-- P pastes without overriding the register - allows multiple pastes of the same thing
vim.keymap.set('v', 'p', 'P', opt)
vim.keymap.set('v', 'P', 'p', opt)
-- Doesn't work in WinTerm
vim.keymap.set('n', '<C-_>', 'gcc', opt) -- <C-/> to comment
vim.keymap.set('v', 'C-_>', 'gc', opt) -- <C-/> to comment
