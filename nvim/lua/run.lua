local M = {}

local function detect_interpreter(bufnr, filepath)
  local first = (vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or "")
  if first:match("^#!") then
    if first:find("zsh", 1, true) then return "zsh" end
    if first:find("bash", 1, true) then return "bash" end
    if first:find("nu", 1, true) or first:find("nushell", 1, true) then return "nu" end
    if first:find("python", 1, true) then return "python" end
    if first:find("node", 1, true) then return "node" end
    if first:find("sh", 1, true) then return "sh" end
  end
  local ext = filepath:match("%.([%w]+)$")
  ext = ext and ext:lower() or ""
  if ext == "yaml" or ext == "yml" then return "bash" end
  if ext == "zsh" then return "zsh" end
  if ext == "sh" or ext == "bash" then return "bash" end
  if ext == "nu" then return "nu" end
  if ext == "py" or ext == "py3" then return "python" end
  if ext == "js" or ext == "mjs" or ext == "cjs" then return "node" end
  return "bash"
end

local function open_in_buffer(out, lines)
  lines = lines or vim.split(out, "\n", { plain = true })
  local b = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(b, "[Run Output]")
  vim.api.nvim_buf_set_option(b, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(b, "modifiable", true)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(b, "modifiable", false)
  vim.cmd("botright split")
  vim.api.nvim_win_set_buf(0, b)
end

local function open_output_float(out)
  local lines = vim.split(out, "\n", { plain = true })
  if #lines == 0 then lines = { "" } end

  local hint = "y: yank  b: buffer  q/Esc/Enter: close"

  local maxw = 0
  for _, l in ipairs(lines) do
    local w = vim.fn.strdisplaywidth(l)
    if w > maxw then maxw = w end
  end
  maxw = math.max(maxw, vim.fn.strdisplaywidth(hint))

  local ui = vim.api.nvim_list_uis()[1] or { width = 100, height = 40 }
  local max_width = math.max(20, math.min(maxw + 2, ui.width - 4))
  local max_height = math.max(3, math.min(#lines + 2, ui.height - 4))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local cfg = {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = max_width,
    height = max_height,
    row = math.floor((ui.height - max_height) / 2),
    col = math.floor((ui.width - max_width) / 2),
  }

  if vim.fn.has("nvim-0.9") == 1 then
    cfg.title = hint
    cfg.title_pos = "center"
  end

  local win = vim.api.nvim_open_win(buf, true, cfg)

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  local function yank_basic()
    vim.fn.setreg('"', out)
    vim.notify("Output yanked", vim.log.levels.INFO)
  end

  local function to_buffer()
    close()
    open_in_buffer(out, lines)
  end

  local opts = { nowait = true, noremap = true, silent = true, buffer = buf }
  vim.keymap.set("n", "y", yank_basic, opts)
  vim.keymap.set("n", "b", to_buffer, opts)
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)
  vim.keymap.set("n", "<CR>", close, opts)

  if vim.fn.has("nvim-0.9") == 0 then
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    table.insert(lines, 1, hint)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
  end

  return win, buf
end

local function show_output(out)
  if not out or #out == 0 then
    vim.notify("(no output)", vim.log.levels.INFO)
    return
  end
  M._last_output = out
  -- default: float; allow env var RUN_OUTPUT_OPEN=buffer to force buffer
  local open_mode = vim.env.RUN_OUTPUT_OPEN or "float"
  if open_mode == "buffer" then
    open_in_buffer(out)
  else
    open_output_float(out)
  end
end

local function stdin_cmd(interp)
  if interp == "bash" then return { "bash", "-s" } end
  if interp == "zsh"  then return { "zsh",  "-s" } end
  if interp == "sh"   then return { "sh",   "-s" } end
  if interp == "python" then return { "python", "-" } end
  if interp == "node"   then return { "node",   "-" } end
  return nil
end

function M.run()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("No file to run", vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then
    vim.cmd("write")
  end
  local interp = detect_interpreter(bufnr, file)
  local out = vim.fn.system({ interp, file })
  show_output(out)
end

function M.run_visual_with_range(s_pos, e_pos, vmode)
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%:p")
  local interp = detect_interpreter(bufnr, file)

  local sr, sc = s_pos[2] - 1, s_pos[3] - 1
  local er, ec_incl = e_pos[2] - 1, e_pos[3] - 1
  if (er < sr) or (er == sr and ec_incl < sc) then
    sr, er = er, sr
    sc, ec_incl = ec_incl, sc
  end

  local lines
  if vmode == 'V' then
    lines = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false)
  elseif vmode == '\22' then
    local all = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false)
    lines = {}
    for i = 1, #all do
      local l = all[i]
      local from = math.min(sc + 1, #l + 1)
      local to = math.min(ec_incl + 1, #l)
      lines[i] = (from <= to) and string.sub(l, from, to) or ""
    end
  else
    local ec_excl = ec_incl + 1
    lines = vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec_excl, {})
  end

  if not lines or #lines == 0 then
    vim.notify("No selection", vim.log.levels.WARN)
    return
  end

  local code = table.concat(lines, "\n")
  local cmd = stdin_cmd(interp)
  local out
  if cmd then
    if not code:match("\n$") then code = code .. "\n" end
    out = vim.fn.system(cmd, code)
  elseif interp == "nu" then
    local tmp = vim.fn.tempname() .. "." .. (vim.fn.expand("%:e") or "")
    vim.fn.writefile(lines, tmp)
    out = vim.fn.system({ "nu", tmp })
    vim.fn.delete(tmp)
  else
    local tmp = vim.fn.tempname() .. "." .. (vim.fn.expand("%:e") or "")
    vim.fn.writefile(lines, tmp)
    out = vim.fn.system({ interp, tmp })
    vim.fn.delete(tmp)
  end
  show_output(out)
end

function M.run_visual()
  local mode = vim.api.nvim_get_mode().mode
  return M.run_visual_with_range(vim.fn.getpos("v"), vim.fn.getpos("."), mode)
end

return M
