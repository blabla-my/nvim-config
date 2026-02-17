return {
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFindFile" },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
      { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Explorer (file)" },
    },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
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
    },
  },
}
