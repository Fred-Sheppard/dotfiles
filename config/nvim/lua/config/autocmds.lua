-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- On startup only: if Neovim was opened with a path (e.g. `nvim foo/bar`), set cwd to
-- that directory (or the file's parent). Does not run on buffer switches — unlike BufEnter.
local did_cd_from_initial_argv = false
local function cd_to_first_startup_arg()
  if did_cd_from_initial_argv then
    return
  end
  local argv = vim.fn.argv()
  if #argv == 0 then
    return
  end
  local first = argv[1]
  if first == nil or first == "" then
    return
  end
  if type(first) == "string" and first:find("^%a[%w+.-]*://") then
    return
  end
  local full = vim.fn.fnamemodify(first, ":p")
  local target ---@type string
  if vim.fn.isdirectory(full) == 1 then
    target = full
  else
    target = vim.fn.fnamemodify(full, ":p:h")
  end
  if target == "" or vim.fn.isdirectory(target) ~= 1 then
    return
  end
  vim.api.nvim_set_current_dir(target)
  did_cd_from_initial_argv = true
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  nested = true,
  callback = cd_to_first_startup_arg,
})

if vim.v.vim_did_enter == 1 then
  cd_to_first_startup_arg()
end

-- Switch out of locked mode when the editor exits
-- vim.api.nvim_create_autocmd("VimLeave", {
--     pattern = "*",
--     callback = function()
--         vim.cmd("echo activated >> /Users/fredsheppard/log.txt")
--     end,
-- })

-- In ~/.config/nvim/lua/config/autocmds.lua or similar
vim.filetype.add({
  extension = {
    kdl = "kdl",
  },
})

-- vim.opt.mouse = ""
