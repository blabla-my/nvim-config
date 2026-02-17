return {
  {
    "Saghen/blink.cmp",
    version = "1.*",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = false } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust" },
    },
  },
}
