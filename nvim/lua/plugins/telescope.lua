return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-lua/plenary.nvim" },
    cmd = "Telescope",
    init = function()
      local builtin = require("telescope.builtin")
      local wk = require("which-key")

      -- Sed snippets (native vim commands)
      -- cmd: string or function(range_start) returning string
      local sed_snippets = {
        { name = "Trim trailing whitespace",       cmd = [[s/\s\+$//e]] },
        { name = "Trim leading whitespace",        cmd = [[s/^\s\+//e]] },
        { name = "Trim leading and trailing",      cmd = [[s/^\s\+//e | s/\s\+$//e]] },
        { name = "Delete blank lines",             cmd = [[g/^$/d]] },
        { name = "Delete consecutive blank lines", cmd = [[g/^$/,/./-j]] },
        { name = "Squeeze multiple spaces to one", cmd = [[s/ \{2,\}/ /ge]] },
        { name = "Double space file",              cmd = [[g/^/pu =\"\"]] },
        { name = "Undo double spacing",            cmd = [[g/^$/d]] },
        { name = "Number each line", cmd = function(rs)
          return ([[s/^/\=printf('%-4d ', line('.') - ]] .. (rs - 1) .. [[)/]])
        end },
        { name = "Remove HTML tags",               cmd = [[s/<[^>]*>//ge]] },
        { name = "DOS to Unix newlines",           cmd = [[s/\r$//e]] },
        { name = "Unix to DOS newlines",           cmd = [[s/$/\r/]] },
        { name = "Quote lines (> prefix)",         cmd = [[s/^/> /]] },
        { name = "Unquote lines (remove > )",      cmd = [[s/^> //e]] },
        { name = "Add commas to numbers",          cmd = [[s/\(\d\)\(\(\d\{3\}\)\+\d\@!\)/\1,\2/g]] },
        { name = "Sort lines",                     cmd = [[sort]] },
        { name = "Sort lines (reverse)",           cmd = [[sort!]] },
        { name = "Remove duplicate lines",         cmd = [[sort u]] },
        { name = "Title Case",                     cmd = [[s/\<./\u&/g]] },
        { name = "Indent 4 spaces",               cmd = [[s/^/    /]] },
        { name = "Remove all indentation",         cmd = [[s/^\s*//]] },
      }

      local function resolve_cmd(snippet, range_start)
        if type(snippet.cmd) == "function" then
          return snippet.cmd(range_start)
        end
        return snippet.cmd
      end

      local function open_sed_picker(opts)
        opts = opts or {}
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Capture visual range BEFORE opening telescope (marks get cleared)
        local is_visual = opts.visual or false
        local range_prefix = "%"
        local range_start = 1
        if is_visual then
          range_start = vim.fn.line("'<")
          local line_end = vim.fn.line("'>")
          range_prefix = range_start .. "," .. line_end
        end

        pickers.new(opts, {
          prompt_title = "Sed Snippets" .. (is_visual and " (selection)" or " (buffer)"),
          finder = finders.new_table({
            results = sed_snippets,
            entry_maker = function(entry)
              return {
                value = entry,
                display = entry.name,
                ordinal = entry.name,
              }
            end,
          }),
          sorter = conf.generic_sorter(opts),
          previewer = require("telescope.previewers").new_buffer_previewer({
            title = "Command",
            define_preview = function(self, entry)
              vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
                "Name: " .. entry.value.name,
                "",
                "Command:",
                "  :" .. range_prefix .. resolve_cmd(entry.value, range_start),
        { "<leader>fS", ":Telescope luasnip<CR>",                                     desc = "Find Snippets", mode = "n" },
      })
            end,
          }),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              actions.close(prompt_bufnr)
              local selection = action_state.get_selected_entry()
              if selection then
                vim.cmd(range_prefix .. resolve_cmd(selection.value, range_start))
              end
            end)
            return true
          end,
        }):find()
      end

      wk.add({
        { "<leader>fb", builtin.buffers,                                                  desc = "Find Buffer" },
        { "<leader>ff", builtin.find_files,                                               desc = "Find File" },
        { "<leader>fg", builtin.live_grep,                                                desc = "Find with Grep" },
        { "<leader>fw", builtin.grep_string,                                              desc = "Find Word under Cursor" },
        { "<leader>fH", builtin.help_tags,                                                desc = "Find Help" },
        { "<leader>fn", ":Telescope file_browser path=%:p:h select_buffer=true<CR>", desc = "File Browser" },
        { "<leader>z", function() require('zellij_tabs').zellij_tabs() end,               desc = "Zellij Tabs" },
        { "<leader>fs", function() open_sed_picker() end,                                 desc = "Sed Snippets", mode = "n" },
        { "<leader>fs", function()
          -- Exit visual mode first so '< and '> marks get set
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
          open_sed_picker({ visual = true })
        end, desc = "Sed Snippets (selection)", mode = "v" },
      })
    end,
    opts = function()
      return {
        defaults = {
          vimgrep_arguments = {
            "rg",
            "-L",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },
          previewer = true,
          file_previewer = require("telescope.previewers").vim_buffer_cat.new,
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
        },
        extensions = {
          file_browser = {
            theme = "ivy",
            hijack_netrw = true,
          },
        },
        extensions_list = {
          "file_browser",
          "luasnip",
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)

      -- load extensions
      for _, ext in ipairs(opts.extensions_list) do
        telescope.load_extension(ext)
      end
    end,
  },
  {
    "kelly-lin/telescope-ag",
    dependencies = { "nvim-telescope/telescope.nvim" },
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
  },
  {
    "benfowler/telescope-luasnip.nvim",
    dependencies = { "nvim-telescope/telescope.nvim", "L3MON4D3/LuaSnip" },
  },
}
