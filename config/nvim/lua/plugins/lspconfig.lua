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
        -- LLVM ships no linux-aarch64 clangd release, so mason bails out with
        -- "This platform is unsupported". install.sh apts it in instead.
        clangd = {
          mason = not (vim.fn.has("linux") == 1 and vim.uv.os_uname().machine == "aarch64"),
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
