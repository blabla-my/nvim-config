vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.termguicolors = true

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
    ensure_plugin("https://github.com/nvim-treesitter/nvim-treesitter.git", pack_start .. "/nvim-treesitter")
    ensure_plugin("https://github.com/nvim-tree/nvim-tree.lua.git", pack_start .. "/nvim-tree.lua")
    pcall(vim.cmd, "packadd blink.cmp")
    pcall(vim.cmd, "packadd friendly-snippets")
    pcall(vim.cmd, "packadd nvim-treesitter")
    pcall(vim.cmd, "packadd nvim-tree.lua")
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

do
  local ok, tree = pcall(require, "nvim-tree")
  if ok then
    tree.setup({
      renderer = {
        icons = {
          show = {
            file = false,
            folder = false,
            folder_arrow = false,
            git = false,
            modified = false,
            diagnostics = false,
            bookmarks = false,
          },
        },
      },
      git = { enable = false },
      view = { width = 30 },
    })
    vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer" })
    vim.keymap.set("n", "<leader>E", "<cmd>NvimTreeFindFile<cr>", { desc = "Explorer (file)" })
  end
end

do
  local ok, ts = pcall(require, "nvim-treesitter")
  if ok then
    ts.setup()

    local function in_path(dir)
      local path = vim.env.PATH or ""
      for entry in string.gmatch(path, "([^:]+)") do
        if entry == dir then
          return true
        end
      end
      return false
    end

    local function prepend_path(dir)
      if dir == nil or dir == "" or in_path(dir) then
        return
      end
      vim.env.PATH = dir .. ":" .. (vim.env.PATH or "")
    end

    local function treesitter_cli_ready()
      if vim.fn.executable("tree-sitter") ~= 1 then
        return false
      end
      local out = vim.trim(vim.fn.system({ "tree-sitter", "--version" }))
      local version = vim.version.parse(out)
      return version ~= nil and vim.version.ge(version, vim.version.parse("0.26.1"))
    end

    local wanted_parsers = { "c", "cpp", "lua", "vim", "vimdoc", "query" }

    local function install_parsers()
      if not treesitter_cli_ready() then
        return
      end
      ts.install(wanted_parsers)
    end

    vim.api.nvim_create_autocmd("VimEnter", {
      group = vim.api.nvim_create_augroup("user-treesitter-bootstrap", { clear = true }),
      once = true,
      callback = function()
        if #vim.api.nvim_list_uis() == 0 then
          return
        end

        if treesitter_cli_ready() then
          install_parsers()
          return
        end

        if vim.fn.executable("cargo") ~= 1 then
          vim.notify(
            "tree-sitter-cli missing; install with: cargo install tree-sitter-cli --locked",
            vim.log.levels.WARN
          )
          return
        end

        if vim.fn.executable("rustc") ~= 1 then
          vim.notify("rustc not found; install Rust (rustup) to build tree-sitter-cli", vim.log.levels.WARN)
          return
        end

        local rustc = vim.trim(vim.fn.system({ "rustc", "--version" }))
        local rustc_ver = vim.version.parse(rustc)
        if not rustc_ver or not vim.version.ge(rustc_ver, vim.version.parse("1.84.0")) then
          vim.notify(
            ("tree-sitter-cli requires Rust >= 1.84 (current: %s). Run `~/.config/nvim/dep.sh` (or `rustup update stable`) and restart Neovim."):format(rustc),
            vim.log.levels.WARN
          )
          return
        end

        local cargo_dir = vim.fn.fnamemodify(vim.fn.exepath("cargo"), ":h")
        prepend_path(cargo_dir)
        prepend_path(
          (vim.env.CARGO_HOME and vim.env.CARGO_HOME ~= "") and (vim.env.CARGO_HOME .. "/bin") or vim.fn.expand("~/.cargo/bin")
        )

        if vim.g._user_installing_tree_sitter_cli then
          return
        end
        vim.g._user_installing_tree_sitter_cli = true

        vim.notify("Installing tree-sitter-cli via cargo (first-time setup)...", vim.log.levels.INFO)
        vim.system({ "cargo", "install", "tree-sitter-cli", "--locked" }, { text = true }, function(res)
          vim.schedule(function()
            vim.g._user_installing_tree_sitter_cli = false
            if res.code ~= 0 then
              local msg = (res.stderr and res.stderr ~= "") and res.stderr or (res.stdout or "")
              vim.notify(("tree-sitter-cli install failed:\n%s"):format(msg), vim.log.levels.ERROR)
              return
            end
            if not treesitter_cli_ready() then
              vim.notify("tree-sitter-cli installed but not found in PATH (restart Neovim).", vim.log.levels.WARN)
              return
            end
            vim.notify("tree-sitter-cli installed; installing parsers...", vim.log.levels.INFO)
            install_parsers()
          end)
        end)
      end,
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
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
