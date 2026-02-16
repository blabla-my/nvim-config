local M = {}

function M.setup()
  local ok, ts = pcall(require, "nvim-treesitter")
  if not ok then
    return
  end

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
        vim.notify("tree-sitter-cli missing; install with: cargo install tree-sitter-cli --locked", vim.log.levels.WARN)
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
      prepend_path((vim.env.CARGO_HOME and vim.env.CARGO_HOME ~= "") and (vim.env.CARGO_HOME .. "/bin") or vim.fn.expand("~/.cargo/bin"))

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

return M
