local M = {}

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

function M.setup()
  local data_dir = vim.fn.stdpath("data")
  if vim.fn.isdirectory(data_dir) == 0 then
    pcall(vim.fn.mkdir, data_dir, "p")
  end

  if vim.fn.filewritable(data_dir) ~= 2 then
    return
  end

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

return M
