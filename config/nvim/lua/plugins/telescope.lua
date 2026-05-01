return {
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      vim.keymap.set("n", "<leader>fc", function()
        local dir = vim.fn.stdpath("config") --[[@as string]]
        vim.api.nvim_set_current_dir(dir)
        LazyVim.pick.open("files", { cwd = dir })
      end, { desc = "Find Config File and change CWD" })
    end,
  },
}
