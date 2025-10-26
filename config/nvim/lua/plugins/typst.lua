return {
  "chomosuke/typst-preview.nvim",
  ft = "typst",
  version = "1.*",
  opts = {},
  config = function(_, opts)
    require("typst-preview").setup(opts)

    -- Create the TypstExport command
    vim.api.nvim_create_user_command("TypstExport", function()
      local buf = vim.api.nvim_get_current_buf()
      local filepath = vim.api.nvim_buf_get_name(buf)

      if filepath == "" then
        vim.notify("No file in current buffer", vim.log.levels.ERROR)
        return
      end

      if not filepath:match("%.typ$") then
        vim.notify("Current file is not a Typst file (.typ)", vim.log.levels.WARN)
        return
      end

      vim.notify("Writing buffer...")
      local ok, err = pcall(function()
        vim.cmd("write")
      end)
      if not ok then
        vim.notify("Failed to write buffer: " .. err, vim.log.levels.ERROR)
        return
      end

      local dir = vim.fn.fnamemodify(filepath, ":h")
      local filename = vim.fn.fnamemodify(filepath, ":t")
      local basename = vim.fn.fnamemodify(filepath, ":t:r")

      local cmd = string.format(
        "cd %s && mkdir -p out && typst compile %s out/%s.pdf && open out/%s.pdf",
        vim.fn.shellescape(dir),
        vim.fn.shellescape(filename),
        basename,
        basename
      )

      vim.notify("Compiling " .. filename .. "...", vim.log.levels.INFO)
      vim.fn.system(cmd)

      if vim.v.shell_error ~= 0 then
        vim.notify("Typst compilation failed", vim.log.levels.ERROR)
      else
        vim.notify("PDF exported to out/" .. basename .. ".pdf", vim.log.levels.INFO)
      end
    end, {
      desc = "Export current Typst file to PDF",
    })
  end,
}
