local M = {}

function M.setup()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  local ok, blink = pcall(require, "blink.cmp")
  if not ok then
    return capabilities
  end

  capabilities = blink.get_lsp_capabilities(capabilities)
  blink.setup({
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    completion = { documentation = { auto_show = false } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust" },
  })

  return capabilities
end

return M
