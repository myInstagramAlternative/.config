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

      local function toggle_telescope(harpoon_list)
        local file_paths = {}
        for _, item in ipairs(harpoon_list.items) do
          table.insert(file_paths, item.value)
        end

        pickers.new({}, {
          prompt_title = "Harpoon",
          finder = finders.new_table({
            results = file_paths,
          }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr, map)
            local function open_with(action)
              local selection = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if not selection then return end
              -- Perform desired action
              vim.cmd(action .. " " .. selection.value)
            end

            -- Map keys to different actions
            map("i", "<C-v>", function() open_with("vsplit") end)
            map("i", "<C-x>", function() open_with("split") end)
            map("i", "<C-t>", function() open_with("tabedit") end)

            map("n", "<C-v>", function() open_with("vsplit") end)
            map("n", "<C-x>", function() open_with("split") end)
            map("n", "<C-t>", function() open_with("tabedit") end)

            return true
          end,
        }):find()
      end

      -- Harpoon keybindings
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end,
        { desc = "Harpoon: add current file" })
      -- NOT WORKING
      -- vim.keymap.set("n", "<leader>d", function() harpoon:list():remove() end,
      -- { desc = "Harpoon: remove current file" })

      -- Use `hh` for Telescope quick menu
      vim.keymap.set("n", "hh", function() toggle_telescope(harpoon:list()) end,
        { desc = "Open Harpoon with Telescope" })

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
