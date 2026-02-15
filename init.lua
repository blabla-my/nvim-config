vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.completeopt = { "menu", "menuone", "noselect" }

local uv = vim.uv or vim.loop

local function git(cwd, args)
  local out = vim.fn.system(vim.list_extend({ "git", "-C", cwd }, args))
  return vim.v.shell_error == 0, out
end

local function ensure_plugin(repo, path)
  if uv.fs_stat(path) then
    return true
  end

  local parent = vim.fn.fnamemodify(path, ":h")
  if vim.fn.isdirectory(parent) == 0 then
    vim.fn.mkdir(parent, "p")
  end

  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", repo, path })
  if vim.v.shell_error ~= 0 then
    vim.notify(("Failed to clone %s:\n%s"):format(repo, out), vim.log.levels.ERROR)
    return false
  end
  return true
end

local function ensure_on_release_tag(path)
  local ok = git(path, { "describe", "--tags", "--exact-match" })
  if ok then
    return true
  end

  local tags_ok, tags_out = git(path, { "tag", "--list", "v1.*", "--sort=-version:refname" })
  if not tags_ok then
    return false
  end

  local latest = vim.split(tags_out, "\n", { plain = true })[1]
  if latest == nil or latest == "" then
    return false
  end

  local checkout_ok, checkout_out = git(path, { "checkout", "--detach", latest })
  if not checkout_ok then
    vim.notify(("Failed to checkout %s:\n%s"):format(latest, checkout_out), vim.log.levels.WARN)
  end
  return checkout_ok
end

do
  local data_dir = vim.fn.stdpath("data")
  if vim.fn.isdirectory(data_dir) == 0 then
    pcall(vim.fn.mkdir, data_dir, "p")
  end

  if vim.fn.filewritable(data_dir) == 2 then
    local pack_start = data_dir .. "/site/pack/plugins/start"
    local blink_path = pack_start .. "/blink.cmp"
    if ensure_plugin("https://github.com/Saghen/blink.cmp.git", blink_path) then
      ensure_on_release_tag(blink_path)
    end
    ensure_plugin("https://github.com/rafamadriz/friendly-snippets.git", pack_start .. "/friendly-snippets")
    pcall(vim.cmd, "packadd blink.cmp")
    pcall(vim.cmd, "packadd friendly-snippets")
  end
end

local capabilities = vim.lsp.protocol.make_client_capabilities()
do
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    capabilities = blink.get_lsp_capabilities(capabilities)
    blink.setup({
      keymap = { preset = "default" },
      appearance = { nerd_font_variant = "mono" },
      completion = { documentation = { auto_show = false } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      fuzzy = { implementation = "prefer_rust" },
    })
  end
end

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
