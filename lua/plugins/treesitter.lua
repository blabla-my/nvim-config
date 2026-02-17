return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter")
      if not ok then
        return
      end

      ts.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user-treesitter", { clear = true }),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("user-treesitter-bootstrap", { clear = true }),
        once = true,
        callback = function()
          if #vim.api.nvim_list_uis() == 0 then
            return
          end

          if vim.fn.executable("tree-sitter") ~= 1 then
            vim.notify("tree-sitter-cli not found. Run `~/.config/nvim/dep.sh`.", vim.log.levels.WARN)
            return
          end

          local wanted = { "c", "cpp", "lua", "vim", "vimdoc", "query" }
          pcall(ts.install, wanted)
        end,
      })
    end,
  },
}
