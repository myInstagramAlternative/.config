return {
  {
    "nvim-mini/mini.surround",
    version = "*",
    event = "VeryLazy",
    opts = {
      mappings = {
        add = "<leader>sa",
        delete = "<leader>sd",
        find = "<leader>sf",
        find_left = "<leader>sF",
        highlight = "<leader>sh",
        replace = "<leader>sr",
        suffix_last = "l",
        suffix_next = "n",
      },
    },
    config = function(_, opts)
      require("mini.surround").setup(opts)
    end,
  },
}
