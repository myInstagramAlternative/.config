return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = "VeryLazy",
    opts = {
      options = {
        icons_enabled = true,
        theme = 'nord',
        component_separators = '|',
        section_separators = { left = '', right = '' },
        nord_contrast = true,
      },
    },
  },
}
