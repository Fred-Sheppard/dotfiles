return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        harper_ls = {
          filetypes = { "typ" },
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
