local M = {}

function M.setup()
  local ok, tree = pcall(require, "nvim-tree")
  if not ok then
    return
  end

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

return M
