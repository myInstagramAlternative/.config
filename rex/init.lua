-- ~/.config/rex/init.lua

local TERM = "com.superlogical.terminal.shell"

-- The Rex server starts with a minimal PATH (/usr/bin:/bin:...), so homebrew
-- and Nix installs aren't on it. Look in the usual places, then ask a login
-- shell, before giving up.
local function find_program(name)
  local home = os.getenv("HOME") or ""
  local user = os.getenv("USER") or ""
  local candidates = {
    "/run/current-system/sw/bin/" .. name,
    "/etc/profiles/per-user/" .. user .. "/bin/" .. name,
    home .. "/.nix-profile/bin/" .. name,
    "/opt/homebrew/bin/" .. name,
    "/usr/local/bin/" .. name,
    home .. "/.local/bin/" .. name,
  }
  for _, path in ipairs(candidates) do
    local f = io.open(path, "r")
    if f then f:close() return path end
  end

  local r = rex.exec({ "/bin/zsh", "-lic", "command -v " .. name })
  if r and r.ok then
    local path = r.stdout:gsub("%s+$", "")
    if path ~= "" then return path end
  end
  return name
end

-- pwd can come back as "file://host/path" (OSC 7 carries the host name), as
-- "file:///path", or as a plain path. Turn any of them into an absolute path,
-- and undo the percent-encoding a URL may use for spaces and the like.
local function to_path(value)
  local host, path = value:match("^file://([^/]*)(/.*)$")
  if path then
    return (path:gsub("%%(%x%x)", function(h)
      return string.char(tonumber(h, 16))
    end))
  end
  return (value:gsub("^file://", ""))
end

-- Working directory of the focused pane: what its shell last reported, or,
-- failing that, where its foreground process actually is.
local function block_cwd(block_id)
  if block_id == nil then return nil end

  local r = rex.block.call("com.superlogical.terminal", "pwd", {
    block_id = block_id,
  })
  if r and r.pwd then return to_path(r.pwd) end

  local p = rex.block.call("com.superlogical.terminal", "process", {
    block_id = block_id,
  })
  if p and p.foreground and p.foreground.cwd then
    return p.foreground.cwd
  end
  return nil
end

rex.action{
  name     = "lazygit",
  title    = "Lazygit (floating)",
  keywords = "git lazygit float scratch",
  run = function(ctx, args)
    local opts = { command = { find_program("lazygit") }, shell = "none" }
    local cwd = block_cwd(ctx.block_id)
    if cwd then opts.cwd = cwd end

    local layer, err = rex.session.new_layer{
      bounds = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
      focus  = true,
      layout = rex.layout.block{ flavor = TERM, options = opts },
    }
    if err ~= nil then error(err, 0) end
    return { layer_id = layer.layer_id, block_ids = layer.block_ids }
  end,
}

rex.bind("cmd+l", "lazygit")

-- Quote values as shell arguments, including paths containing apostrophes.
local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

rex.action{
  name = "open_dev_dir",
  title = "Open Development Directory",
  args = { dir = "string" },
  run = function(ctx, args)
    local dir = to_path(args.dir):gsub("/+$", "")
    if dir == "" then dir = "/" end
    local label = dir:match("([^/]+)$") or "/"
    -- Rex uses OSC 7 directory reports when creating subsequent splits.
    -- Publish the selected directory before starting the applications.
    local directory_url = "file://localhost" .. dir:gsub("([^%w/_.~-])", function(c)
      return string.format("%%%02X", string.byte(c))
    end)

    local function program_pane(name)
      return rex.layout.block{
        flavor = TERM,
        options = {
          cwd = dir,
          shell = "none",
          -- -e runs startup commands and then enters Nushell's REPL, so
          -- quitting the app (including Ctrl+C) leaves a usable terminal.
          command = { "/run/current-system/sw/bin/nu", "-l", "-e",
            "cd " .. rex.json.encode(dir)
              .. "; ^/usr/bin/printf '\\033]7;%s\\007' "
              .. rex.json.encode(directory_url)
               .. "; ^" .. rex.json.encode(find_program(name))
               .. (name == "nvim" and (' ' .. rex.json.encode("+FFFTOP2")) or "") },
        },
      }
    end

    local window, err = rex.session.new_window{
      window_label = label,
      focus = true,
      layout = rex.layout.horizontal(0.65,
        program_pane("nvim"), program_pane("opencode")),
    }
    if err ~= nil then error(err, 0) end
    -- Server focus alone doesn't select the tab in the Mac app.
    rex.client.queue("session.select", {
      session_id = ctx.session_id,
      window_id = window.window_id,
    })
    return window
  end,
}

rex.action{
  name = "devtab",
  title = "devtab",
  run = function(ctx, args)
    local rex_cli = (os.getenv("HOME") or "")
      .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
    local command = "dir=$(" .. shell_quote(find_program("zoxide"))
      .. " query --interactive) || exit 0\n"
      .. '[ -n "$dir" ] || exit 0\n'
      .. "exec " .. shell_quote(rex_cli)
      .. (ctx.client_id and (" -C " .. shell_quote(ctx.client_id)) or "")
      .. " do -s "
      .. shell_quote(assert(ctx.session_id, "No active Rex session"))
      .. ' open_dev_dir "dir=$dir"'

    local layer, err = rex.session.new_layer{
      bounds = { x = 0.1, y = 0.1, w = 0.8, h = 0.8 },
      focus = true,
      layout = rex.layout.block{
        flavor = TERM,
        options = {
          cwd = block_cwd(ctx.block_id),
          shell = "none",
          command = { "/bin/zsh", "-lic", command },
          exit = { on_completion = true },
        },
      },
    }
    if err ~= nil then error(err, 0) end
    return layer
  end,
}
