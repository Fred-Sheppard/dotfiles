return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        harper_ls = {
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
