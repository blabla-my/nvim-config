return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>/",
        function()
          require("snacks").picker.grep()
        end,
        desc = "Global Grep",
      },
    },
    opts = {
      picker = {
        enabled = true,
      },
    },
  },
}
