return {
  "saghen/blink.cmp",
  opts = function(_, opts)
    opts.keymap = opts.keymap or {}
    opts.keymap.preset = "none"

    opts.keymap["<Tab>"] = { "select_next", "fallback" }
    opts.keymap["<Down>"] = { "select_next", "fallback" }
    opts.keymap["<S-Tab>"] = { "select_prev", "fallback" }
    opts.keymap["<Up>"] = { "select_prev", "fallback" }
    opts.keymap["<CR>"] = { "select_and_accept", "fallback" }

    opts.enabled = function()
      local ft = vim.bo.filetype
      local disabled = {
        txt = true,
        text = true,
        markdown = true,
        md = true,
        asciidoc = true,
        adoc = true,
      }
      return not disabled[ft]
    end
  end,
}
