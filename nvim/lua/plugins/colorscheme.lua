return {
	{
		"folke/tokyonight.nvim",
		name = "tokyonight",
		priority = 1000,
		style = "night", -- "storm", "day", "moon", "night"
		terminal_colors = true,
		transparent = true,
		styles = {
			comments = { italic = true },
			sidebars = "transparent",
			floats = "transparent",
		},
		config = function()
			vim.cmd([[colorscheme tokyonight-night]])
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		-- config = function()
		-- 	vim.cmd([[colorscheme rose-pine]])
		-- end,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		priority = 1000,
	},
}
