return {
	{
		"nvim-treesitter/nvim-treesitter",
		event = { "BufReadPost", "BufNewFile" },
		cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
		build = ":TSUpdate",
		dependencies = {
			"apple/pkl-neovim",
			"windwp/nvim-ts-autotag",
		},
		opts = function()
			return require("plugins.configs.treesitter")
		end,
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)

			local query = require("vim.treesitter.query")

			local html_script_type_languages = {
				importmap = "json",
				module = "javascript",
				["application/ecmascript"] = "javascript",
				["text/ecmascript"] = "javascript",
			}

			local non_filetype_match_injection_language_aliases = {
				ex = "elixir",
				pl = "perl",
				sh = "bash",
				uxn = "uxntal",
				ts = "typescript",
			}

			local function first_capture(match, capture_id)
				local capture = match[capture_id]
				if type(capture) == "table" then
					return capture[1]
				end
				return capture
			end

			local function get_parser_from_markdown_info_string(injection_alias)
				local match = vim.filetype.match({ filename = "a." .. injection_alias })
				return match or non_filetype_match_injection_language_aliases[injection_alias] or injection_alias
			end

			query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
				local capture_id = pred[2]
				local node = first_capture(match, capture_id)
				if not node then
					return
				end

				local type_attr_value = vim.treesitter.get_node_text(node, bufnr)
				local configured = html_script_type_languages[type_attr_value]
				if configured then
					metadata["injection.language"] = configured
				else
					local parts = vim.split(type_attr_value, "/", {})
					metadata["injection.language"] = parts[#parts]
				end
			end, { force = true })

			query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
				local capture_id = pred[2]
				local node = first_capture(match, capture_id)
				if not node then
					return
				end

				local injection_alias = vim.treesitter.get_node_text(node, bufnr):lower()
				metadata["injection.language"] = get_parser_from_markdown_info_string(injection_alias)
			end, { force = true })

			query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
				local capture_id = pred[2]
				local node = first_capture(match, capture_id)
				if not node then
					return
				end

				local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[capture_id] }) or ""
				metadata[capture_id] = metadata[capture_id] or {}
				metadata[capture_id].text = string.lower(text)
			end, { force = true })
		end,
	},
}
