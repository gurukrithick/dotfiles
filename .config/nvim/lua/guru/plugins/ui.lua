return {
	-- mock keeps plugins that require nvim-web-devicons working
	{
		"echasnovski/mini.icons",
		lazy = true,
		opts = {},
		init = function()
			package.preload["nvim-web-devicons"] = function()
				require("mini.icons").mock_nvim_web_devicons()
				return package.loaded["nvim-web-devicons"]
			end
		end,
	},

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "echasnovski/mini.icons" },
		opts = function()
			local statusline = require("guru.statusline")
			return {
				options = {
					theme = statusline.theme,
					component_separators = "",
					section_separators = "",
					globalstatus = true,
					disabled_filetypes = { statusline = { "lazy", "mason", "ministarter" } },
				},
				sections = statusline.sections,
				extensions = statusline.extensions,
			}
		end,
	},

	{
		"nvim-mini/mini.starter",
		event = "VimEnter",
		opts = function()
			return require("guru.starter").opts()
		end,
	},

	{
		"nvim-mini/mini.indentscope",
		event = { "BufReadPost", "BufNewFile" },
		opts = function()
			return {
				symbol = "\u{2502}",
				options = { try_as_border = true },
				draw = { delay = 60, animation = require("mini.indentscope").gen_animation.none() },
			}
		end,
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "help", "lazy", "mason", "ministarter", "oil", "fzf", "man", "markdown" },
				callback = function(args)
					vim.b[args.buf].miniindentscope_disable = true
				end,
			})
		end,
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			spec = {
				{ "<leader>c", group = "code" },
				{ "<leader>e", group = "explorer" },
				{ "<leader>f", group = "find" },
				{ "<leader>g", group = "git" },
				{ "<leader>o", group = "sessions" },
				{ "gz", group = "surround" },
				{ "<leader>r", group = "rename/replace" },
				{ "<leader>s", group = "split" },
				{ "<leader>t", group = "tabs" },
				{ "g", group = "goto" },
				{ "z", group = "fold/spell" },
				{ "]", group = "next" },
				{ "[", group = "prev" },
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer local keymaps",
			},
		},
	},
}
