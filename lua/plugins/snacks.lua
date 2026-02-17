return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    keys = {
      {
        "<leader><space>",
        function()
          require("snacks").picker()
        end,
        desc = "Pickers",
      },
      {
        "<leader>ff",
        function()
          require("snacks").picker.files()
        end,
        desc = "Find Files",
      },
      {
        "<leader>/",
        function()
          require("snacks").picker.grep()
        end,
        desc = "Grep",
      },
    },
    opts = {
      picker = {
        enabled = true,
        ui_select = false,
      },
    },
  },
}
