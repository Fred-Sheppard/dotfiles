-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
local autocmd = vim.api.nvim_create_autocmd

-- Auto-change to the file's directory on open
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*",
  callback = function()
    -- Get the buffer name (file path associated with the buffer)
    local bufname = vim.fn.bufname("%")

    -- Proceed only if the buffer has a name (i.e., it's not an unnamed buffer like [No Name])
    if bufname ~= "" and bufname ~= "[No Name]" then
      -- Get the absolute path to the directory containing the buffer's file
      -- :p expands to full path, :h gets the head (directory part)
      local target_dir = vim.fn.fnamemodify(bufname, ":p:h")

      -- Check if the calculated directory path is not empty and actually exists on the filesystem
      -- vim.fn.isdirectory() returns 1 if it exists and is a directory, 0 otherwise.
      if target_dir ~= "" and vim.fn.isdirectory(target_dir) == 1 then
        -- Use fnameescape to handle potential spaces or special characters in the path
        local escaped_dir = vim.fn.fnameescape(target_dir)
        -- Change the current working directory
        vim.cmd("cd " .. escaped_dir)
      end
    end
  end,
  desc = "Change CWD to buffer's directory on entering buffer", -- Optional description
})

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

-- Add custom command for Typst export
vim.api.nvim_create_user_command("ExportTypst", function()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)

  -- Check if buffer has a file
  if filepath == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR)
    return
  end

  -- Check if it's a .typ file
  if not filepath:match("%.typ$") then
    vim.notify("Current file is not a Typst file (.typ)", vim.log.levels.WARN)
    return
  end

  -- Extract directory and filename
  local dir = vim.fn.fnamemodify(filepath, ":h")
  local filename = vim.fn.fnamemodify(filepath, ":t")
  local basename = vim.fn.fnamemodify(filepath, ":t:r")

  -- Build the command
  local cmd = string.format(
    "cd %s && mkdir -p out && typst compile %s out/%s.pdf && open out/%s.pdf",
    vim.fn.shellescape(dir),
    vim.fn.shellescape(filename),
    basename,
    basename
  )

  -- Execute the command
  vim.notify("Compiling " .. filename .. "...", vim.log.levels.INFO)
  vim.fn.system(cmd)

  -- Check for errors
  if vim.v.shell_error ~= 0 then
    vim.notify("Typst compilation failed", vim.log.levels.ERROR)
  else
    vim.notify("PDF exported to out/" .. basename .. ".pdf", vim.log.levels.INFO)
  end
end, {
  desc = "Export current Typst file to PDF",
})
