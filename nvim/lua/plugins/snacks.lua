local banned_messages = { "No information available" }
return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      bigfile = { enabled = true },
      dashboard = {
        enabled = true,
        preset = {
          keys = {
            { icon = " ", key = "n", desc = "New File",        action = ":ene | startinsert" },
            { icon = " ", key = "r", desc = "Recent Files",    action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config",          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "L", desc = "Lazy",            action = ":Lazy",                                                                enabled = package.loaded.lazy ~= nil },
          },
          header = [[╺┓ ┏━┓╺┓ ╻ ╻
 ┃ ┗━┫ ┃ ┗━┫
 ╺┻╸┗━┛╺┻╸  ╹╹]],
        },
        sections = {
          { section = "header", align = "center", padding = 1 },
          { section = "keys",   gap = 1,          padding = 1 },
          { section = "startup" },
        },
      },
      explorer = { enabled = true },
      indent = { enabled = true },
      input = { enabled = true },
      picker = { enabled = true },
      notifier = {
        enabled = true,
        filter = function(notif)
          for _, banned in ipairs(banned_messages) do
            if notif.msg == banned then
              return false
            end
          end
          return true
        end,
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true, animation = false },
      statuscolumn = { enabled = true },
      words = { enabled = true },
    },
    keys = {
      { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },
    },
  }
}
