local M = {}

function M.setup()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  local uv = vim.uv or vim.loop

  if not uv.fs_stat(lazypath) then
    local out = vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "--branch=stable",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
    if vim.v.shell_error ~= 0 then
      vim.notify(("Failed to install lazy.nvim:\n%s"):format(out), vim.log.levels.ERROR)
      return
    end
  end

  vim.opt.rtp:prepend(lazypath)

  require("lazy").setup("plugins", {
    lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
    install = { missing = true },
    checker = { enabled = false },
    change_detection = { notify = false },
  })
end

return M
