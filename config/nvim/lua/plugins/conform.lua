return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters = opts.formatters or {}

    opts.formatters_by_ft.kdl = { "kdlfmt" }
    opts.formatters.kdlfmt = {
      command = "kdlfmt",
      args = { "format", "-" },
      stdin = true,
    }

    opts.formatters_by_ft.lua = { "stylua" }
    opts.formatters.stylua = {
      prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
    }
  end,
}
