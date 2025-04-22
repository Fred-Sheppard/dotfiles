return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    -- Add the KDL formatter
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.kdl = { "kdlfmt" }

    -- Register kdlfmt as a formatter
    opts.formatters = opts.formatters or {}
    opts.formatters.kdlfmt = {
      command = "kdlfmt",
      args = { "format", "-" }, -- The "--" argument tells it to read from stdin
      stdin = true,
    }
  end,
}
