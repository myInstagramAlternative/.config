return {
  {
    "stevearc/conform.nvim",
    dependencies = { "mason.nvim" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cF",
        function()
          require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
        end,
        mode = { "n", "v" },
        desc = "Format Injected Langs",
      },
    },
    init = function()
      -- You may want to follow a similar pattern as telescope, with local setup
      -- If LazyVim isn't available, remove its references or ensure correct usage
    end,
    opts = function()
      return {
        default_format_opts = {
          timeout_ms = 3000,
          async = false,
          quiet = false,
          lsp_format = "fallback",
        },
        formatters_by_ft = {
          lua = { "stylua" },
          fish = { "fish_indent" },
          sh = { "shfmt" },
        },
        formatters = {
          injected = { options = { ignore_errors = true } },
          -- Additional formatter configurations could be specified here:
          -- e.g., dprint, shfmt with custom args
        },
      }
    end,
    config = function(_, opts)
      -- Handle the setup using provided options
      local conform = require("conform")
      conform.setup(opts)
      -- Additional setup logic or extension loading can go here
    end,
  },
  -- Additional modules or integrations can be added here, similar to telescope extensions
}

