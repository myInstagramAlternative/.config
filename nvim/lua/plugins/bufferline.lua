return {
  {
    'akinsho/bufferline.nvim',
    event = "VeryLazy",
    version = "*",
    dependencies = { 'nvim-tree/nvim-web-devicons', 'shaunsingh/nord.nvim' },
    options = {
      separator_style = "slant",
      hover = {
        enabled = true,
        delay = 200,
        reveal = { 'close' }
      },
      -- mode = "tabs",
      diagnostics = "nvim_lsp", -- "coc",

    },
    config = function()
      local nord = require("nord")
      require("bufferline").setup({
        highlights = nord.bufferline.highlights({
          italic = true,
          bold = true,
          fill = "#181c24"
        }),
        options = {
          separator_style = "slant",
          hover = {
            enabled = true,
            delay = 200,
            reveal = { 'close' }
          },
        }
      })
    end,
  }
}
