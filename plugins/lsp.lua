local M = {}

function M.setup(capabilities)
  capabilities = capabilities or vim.lsp.protocol.make_client_capabilities()

  if vim.fn.executable("clangd") == 1 then
    vim.lsp.config.clangd = {
      cmd = {
        "clangd",
        "--offset-encoding=utf-8",
      },
      root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", ".git" },
      filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
      capabilities = capabilities,
    }
    vim.lsp.enable("clangd")
  else
    vim.notify("clangd not found in PATH", vim.log.levels.WARN)
  end

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user-lsp-keymaps", { clear = true }),
    callback = function(args)
      local opts = { buffer = args.buf }
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "<leader>f", function()
        vim.lsp.buf.format({ async = true })
      end, opts)
    end,
  })
end

return M
