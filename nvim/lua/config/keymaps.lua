-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local opt = {
  noremap = true,
  silent = true,
}

local set = vim.keymap.set

-- Select All
set("n", "<leader>a", "ggVG", opt)

-- Start and end of line
set("n", "H", "^", opt) -- Move to the beginning of the line
set("n", "L", "$", opt) -- Move to the end of the line
set("v", "H", "^", opt) -- Move to the beginning of the line
set("v", "L", "$", opt) -- Move to the end of the line

-- Move between buffers
set("n", "<Tab>", ":bnext<CR>", opt) -- Next buffer
set("n", "<S-Tab>", ":bprevious<CR>", opt) -- Previous buffer

-- zz scrolls to 35%
set("n", "zz", function()
  local win_height = vim.api.nvim_win_get_height(0) -- Get current window height
  local offset = math.floor(win_height * 0.35) -- Calculate 35% of the height
  local current_line = vim.fn.line(".") -- Get the current cursor line
  local target_line = current_line - offset -- Move to the target line
  vim.fn.winrestview({ topline = target_line }) -- Scroll to the target line
end, opt)

-- Alt movement instead of Ctrl
set("n", "<M-j>", "<C-w>j", opt)
set("n", "<M-k>", "<C-w>k", opt)
set("n", "<M-h>", "<C-w>h", opt)
set("n", "<M-l>", "<C-w>l", opt)

-- # key (lmaoooo)
-- set("n", "<leader>3", "a#", opt)

-- Move to zellij tab #2
-- set("n", "<leader>nv", "::silent !nvim-switch-zellij.sh<CR>", opt)

-- P pastes without overriding the register - allows multiple pastes of the same thing
set("v", "p", "P", opt)
set("v", "P", "p", opt)

vim.keymap.del({ "n" }, "<leader>w")
set("n", "<leader>w", ":w<CR>", opt)
