-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.scrolloff = 3

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.cmd("au BufRead,BufNewFile *.templ setfiletype templ")

vim.api.nvim_create_autocmd({ "BufEnter", "BufNewFile" }, {
	pattern = { "*.templ" },
	callback = function()
		local buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_option(buf, "filetype", "templ")
	end,
})

vim.api.nvim_set_keymap('i', 'jj', '<Esc>', { noremap = true })

-- Since clipboard is disabled, yank to 0 register and then copy to clipboard
vim.api.nvim_set_keymap('n', '<leader>c', ':let @+=@0<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', '<leader>c', '"0y:let @+=@0<CR>', { noremap = true, silent = true })

vim.opt.rtp:prepend(lazypath)

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Tabs vs spaces
vim.o.tabstop = 2      -- A TAB character looks like 4 spaces
vim.o.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.o.softtabstop = 2  -- Number of spaces inserted instead of a TAB character
vim.o.shiftwidth = 2   -- Number of spaces inserted when indenting

-- Enable mouse mode
vim.o.mouse = "a"
-- Used in bufferline for hovering over buffer tabs
vim.o.mousemoveevent = true

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
-- vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Write buffer on leaving insert mode
-- local autocmd = vim.api.nvim_create_autocmd
-- autocmd("InsertLeave", {
-- 	pattern = "*",
-- 	command = "write"
-- })

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- Set terminal gui colors to true
vim.o.termguicolors = true

-- add binaries installed by mason.nvim to path
local is_windows = vim.loop.os_uname().sysname == "Windows_NT"
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

require("lazy").setup("plugins")
