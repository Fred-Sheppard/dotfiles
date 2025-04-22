return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    -- Add KDL to the list of parsers to install
    if type(opts.ensure_installed) == "table" then
      vim.list_extend(opts.ensure_installed, { "kdl" })
    end
  end,
}
