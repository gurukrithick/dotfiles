-- lspconfig depends on this for capabilities, so not lazy on InsertEnter

return {
	"saghen/blink.cmp",
	version = "1.*",
	opts = {
		keymap = {
			preset = "default", -- <C-n>/<C-p> select, <C-y> accept, <C-e> hide, <C-space> docs
			["<Tab>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<C-d>"] = { "scroll_documentation_down", "fallback" },
		},

		snippets = { preset = "default" },

		signature = { enabled = true },

		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
		},

		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 500 },
			ghost_text = { enabled = false },
			menu = { border = "rounded" },
			-- tab inserts items as you cycle, <C-e> undoes
			list = { selection = { preselect = false, auto_insert = true } },
		},

		appearance = { nerd_font_variant = "mono" },

		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
