return {
    "saghen/blink.cmp",
    opts = {
        keymap = {
            preset = "none",
            ["<Tab>"] = { "select_next", "fallback" },
            ["<S-Tab>"] = { "select_prev", "fallback" },
            ["<CR>"] = { "select_and_accept", "fallback" },
        },
    },
}
