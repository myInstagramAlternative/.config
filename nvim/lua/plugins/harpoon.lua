return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    config = function()
      local harpoon = require("harpoon")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values

      harpoon:setup()

      -- Harpoon keybindings
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end,
        { desc = "Harpoon: add current file" })

      -- Use `hh` for Telescope quick menu
      vim.keymap.set("n", "hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
        { desc = "Harpoon: quick menu" })

      vim.keymap.set("n", "h1", function() harpoon:list():select(1) end,
        { desc = "Harpoon: select mark 1" })
      vim.keymap.set("n", "h2", function() harpoon:list():select(2) end,
        { desc = "Harpoon: select mark 2" })
      vim.keymap.set("n", "h3", function() harpoon:list():select(3) end,
        { desc = "Harpoon: select mark 3" })
      vim.keymap.set("n", "h4", function() harpoon:list():select(4) end,
        { desc = "Harpoon: select mark 4" })
      vim.keymap.set("n", "hp", function() harpoon:list():prev() end,
        { desc = "Harpoon: go to previous mark in list" })
      vim.keymap.set("n", "hn", function() harpoon:list():next() end,
        { desc = "Harpoon: go to next mark in list" })
    end,
  },
}
