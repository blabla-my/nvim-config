vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.termguicolors = true

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.lazy").setup()
