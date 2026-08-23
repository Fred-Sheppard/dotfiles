return {
  {
    "unblevable/quick-scope",
    lazy = true,
    init = function()
      -- quick-scope's matchadd() highlights default to priority 1, which
      -- is enough to beat syntax highlighting but not our manual backdrop
      -- extmark below (priority 5000) — raise it so the highlighted
      -- characters still show through the dim.
      vim.g.qs_hi_priority = 6000
    end,
  },
  {
    "folke/flash.nvim",
    dependencies = { "unblevable/quick-scope" },
    opts = {
      modes = {
        char = {
          -- disable flash's own backdrop dimming and match highlighting for
          -- f/F/t/T. flash's backdrop is baked into its state at creation
          -- and stays on through the jump and any `;`/`,` repeats, so it
          -- can't give the "only while waiting for the target char" timing
          -- we want; a manual backdrop bracketing just that wait is wired
          -- in below instead. multi-line jumping stays on.
          highlight = { backdrop = false, matches = false },
        },
      },
    },
    config = function(_, opts)
      require("flash").setup(opts)

      -- Even with highlight.matches/backdrop off, flash still draws a
      -- one-character highlight per match via its label extmarks (used to
      -- mark the position when jump_labels is off), and each motion's
      -- entry in flash.plugins.char hardcodes label.after/before, which
      -- overrides modes.char.label at merge time. Patch those directly so
      -- `;`/`,` repeats don't bring flash's highlight back.
      for _, motion in pairs(require("flash.plugins.char").motions) do
        motion.label = motion.label or {}
        motion.label.after = false
        motion.label.before = false
      end

      -- quick-scope's own "highlight on keys" mode maps f/F/t/T itself,
      -- which conflicts with flash's f/F/t/T mapping. Instead, let it load
      -- in its default "vanilla" mode (sets no keymaps), then clear the
      -- CursorMoved autocmds it uses to highlight on every cursor move, so
      -- we can trigger the same highlight/unhighlight functions ourselves
      -- only while flash is waiting for the target character below.
      vim.api.nvim_clear_autocmds({ group = "quick_scope" })

      -- Backdrop shown only while waiting for the f/F/t/T target char, to
      -- make quick-scope's highlighted characters stand out. Drawn by hand
      -- (rather than via flash's own highlight.backdrop) so it can be
      -- cleared the instant a target is typed, instead of lingering
      -- through the jump and `;`/`,` repeats.
      local backdrop_ns = vim.api.nvim_create_namespace("flash_char_quickscope_backdrop")

      local function show_backdrop()
        local buf = vim.api.nvim_get_current_buf()
        for line = vim.fn.line("w0"), vim.fn.line("w$") do
          vim.api.nvim_buf_set_extmark(buf, backdrop_ns, line - 1, 0, {
            end_row = line,
            hl_group = "FlashBackdrop",
            hl_eol = true,
            -- must outrank treesitter highlighting (priority ~100) or the
            -- overlay is invisible; match flash's own default priority
            priority = 5000,
          })
        end
      end

      local function hide_backdrop()
        vim.api.nvim_buf_clear_namespace(0, backdrop_ns, 0, -1)
      end

      for _, key in ipairs({ "f", "F", "t", "T" }) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          local direction = (key == "f" or key == "t") and 1 or 0
          show_backdrop()
          vim.fn["quick_scope#HighlightLine"](direction, vim.g.qs_accepted_chars)
          vim.cmd("redraw")
          require("flash.plugins.char").jump(key)
          hide_backdrop()
          vim.fn["quick_scope#UnhighlightLine"]()
        end, { silent = true })
      end
    end,
  },
}
