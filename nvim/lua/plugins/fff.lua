return {
  "dmtrKovalenko/fff",
  build = function()
    require("fff.download").download_or_build_binary()
  end,
  opts = {
    debug = {
      enabled = true,
      show_scores = true,
    },
  },
  lazy = false,
  keys = {
    { "ff", function() require('fff').find_files() end, desc = 'Find files' },
    { "fg", function() require('fff').live_grep() end, desc = 'Live grep' },
    { "fz", function() require('fff').live_grep({ grep = { modes = { 'fuzzy', 'plain' } } }) end, desc = 'Fuzzy grep' },
    { "fw", function() require('fff').live_grep_under_cursor() end, mode = { 'n', 'x' }, desc = 'Search current word / selection' },
  },
}