-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
local opt = {
  noremap = true,
  silent = true,
}

local set = vim.keymap.set

set("n", "<leader>a", "ggVG", opt)
set({ "n", "v" }, "H", "^", opt)
set({ "n", "v" }, "L", "$", opt)
set({ "n", "v" }, "gH", "g^", opt)
set({ "n", "v" }, "gL", "g$", opt)
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

-- P pastes without overriding the register - allows multiple pastes of the same thing
set("v", "p", "P", opt)
set("v", "P", "p", opt)

set("n", "<leader>w", ":w<CR>", opt)

-- Disable Leader Q as session management
-- While not required (if you hit the keys fast enough,
-- it quits even with these enabled),
-- this does makes quitting snappier.
vim.keymap.del("n", "<leader>qq")
vim.keymap.del("n", "<leader>ql")
vim.keymap.del("n", "<leader>qd")
vim.keymap.del("n", "<leader>qs")
vim.keymap.del("n", "<leader>qS")
set("n", "<leader>q", ":qa<CR>", opt)

set("n", "<leader>r", ":!zellij action toggle-floating-panes<CR>", opt)

-- Recent buffers
vim.keymap.set("n", "<Tab>", function()
  require("telescope.builtin").buffers({
    sort_mru = true,
    ignore_current_buffer = true,
    initial_mode = "normal",
  })
end, { desc = "Switch buffers" })

set("n", "<F12>", "<C-i>", opt)
