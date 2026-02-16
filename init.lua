vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.completeopt = { "menu", "menuone", "noselect" }

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.termguicolors = true

do
  local config_dir = vim.fn.stdpath("config")
  local extra_paths = {
    config_dir .. "/?.lua",
    config_dir .. "/?/init.lua",
  }
  for _, p in ipairs(extra_paths) do
    if not string.find(package.path, p, 1, true) then
      package.path = p .. ";" .. package.path
    end
  end
end

require("plugins.bootstrap").setup()

local capabilities = require("plugins.blink").setup()
require("plugins.nvim_tree").setup()
require("plugins.treesitter").setup()
require("plugins.lsp").setup(capabilities)
