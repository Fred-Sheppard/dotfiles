return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            {
              "<leader>ss",
              function()
                require("telescope.builtin").lsp_document_symbols({
                  ignore_symbols = { "field", "enummember" },
                })
              end,
              desc = "Goto Symbol (no fields)",
            },
          },
        },
        harper_ls = {
          filetypes = { "typst" },
          settings = {
            ["harper-ls"] = {
              linters = {
                SentenceCapitalization = false,
                SpellCheck = false,
                ToDoHyphen = false,
              },
              dialect = "British",
            },
          },
        },
        tinymist = {
          settings = {
            formatterMode = "typstyle",
          },
        },
      },
    },
  },
}
