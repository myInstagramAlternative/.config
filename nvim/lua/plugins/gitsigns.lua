return {
  "lewis6991/gitsigns.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    current_line_blame = false, -- Toggle current line blame visibility with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = { delay = 200 }, -- Delay in milliseconds for current line blame
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "gj", function()
        if vim.wo.diff then
          vim.cmd.normal({ "gj", bang = true }) -- Vim's default movement in diff mode
        else
          gitsigns.nav_hunk("next") -- Jump to the next hunk
        end
      end, { desc = "Next Hunk" })

      map("n", "gk", function()
        if vim.wo.diff then
          vim.cmd.normal({ "gk", bang = true }) -- Vim's default movement in diff mode
        else
          gitsigns.nav_hunk("prev") -- Jump to the previous hunk
        end
      end, { desc = "Previous Hunk" })

      -- Actions
      map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "Stage Hunk" }) -- Stage the selected hunk
      map("v", "<leader>hs", function() gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Stage Hunk (Visual)" })
      map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "Reset Hunk" }) -- Reset the changes in the selected hunk
      map("v", "<leader>hr", function() gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "Reset Hunk (Visual)" })
      map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "Stage Buffer" }) -- Stage all changes in the buffer
      map("n", "<leader>hu", gitsigns.undo_stage_hunk, { desc = "Undo Stage Hunk" }) -- Undo the staging of a hunk
      map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "Reset Buffer" }) -- Reset all changes in the buffer
      map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "Preview Hunk" }) -- Preview the changes in the selected hunk
      map("n", "<leader>hb", function() gitsigns.blame_line({ full = true }) end, { desc = "Blame Line" }) -- Show blame information for the current line
      map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "Toggle Current Line Blame" }) -- Toggle the display of blame for the current line
      map("n", "<leader>hd", gitsigns.diffthis, { desc = "Diff This" }) -- Show a diff of the current buffer
      map("n", "<leader>hD", function() gitsigns.diffthis("~") end, { desc = "Diff This (Index)" }) -- Show a diff against the index
      map("n", "<leader>td", gitsigns.toggle_deleted, { desc = "Toggle Deleted" }) -- Toggle the display of deleted lines

      -- Text object
      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select Hunk" }) -- Define a text object for a hunk
    end,
  },
}
