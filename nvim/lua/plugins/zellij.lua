return {
  'https://github.com/fresh2dev/zellij.vim',
  -- Pin version to avoid breaking changes.
  -- tag = '0.3.*',
  lazy = false,
  init = function()
    -- Let the plugin set up its default mappings
    -- vim.g.zellij_navigator_no_default_mappings = 1
    -- Options:
    -- vim.g.zellij_navigator_move_focus_or_tab = 1
  end,
}