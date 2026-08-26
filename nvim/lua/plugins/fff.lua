return {
  "dmtrKovalenko/fff",
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  opts = {
    debug = {
      enabled = false,
      show_scores = true,
    },
  },
  lazy = false,
  keys = {
    { "<leader>ff", function() require('fff').find_files() end, desc = 'Find files' },
    { "<leader>fg", function() require('fff').live_grep() end, desc = 'Live grep' },
    { "<leader>fz", function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } }) end, desc = 'Fuzzy grep' },
    { "<leader>fw", function() require('fff').live_grep_under_cursor() end, mode = { 'n', 'x' }, desc = 'Search current word / selection' },
  },
}
