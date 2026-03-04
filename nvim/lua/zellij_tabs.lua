local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local M = {}

local function open_picker(lines)
  if not lines or #lines == 0 then
    vim.notify('zellij: no tabs found', vim.log.levels.WARN)
    return
  end
  pickers.new({}, {
    prompt_title = 'Zellij Tabs',
    finder = finders.new_table({ results = lines }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(bufnr, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(bufnr)
        if entry and entry[1] then
          if vim.system then
            vim.system({ 'zellij', 'action', 'go-to-tab-name', entry[1] })
          else
            vim.fn.jobstart({ 'zellij', 'action', 'go-to-tab-name', entry[1] })
          end
        end
      end)
      return true
    end,
  }):find()
end

function M.zellij_tabs()
  if vim.system then
    vim.system({ 'zellij', 'action', 'query-tab-names' }, { text = true }, function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          vim.notify('zellij: ' .. (res.stderr or 'no active session'), vim.log.levels.WARN)
        end)
        return
      end
      local lines = vim.split(res.stdout or '', '\n', { trimempty = true })
      vim.schedule(function()
        open_picker(lines)
      end)
    end)
  else
    local out = vim.fn.systemlist({ 'zellij', 'action', 'query-tab-names' })
    if vim.v.shell_error ~= 0 then
      vim.notify('zellij: failed: ' .. table.concat(out or {}, '\n'), vim.log.levels.WARN)
      return
    end
    open_picker(out)
  end
end

return M
