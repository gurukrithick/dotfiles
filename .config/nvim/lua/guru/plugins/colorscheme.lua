-- guru/theme.lua picks the scheme; transparent because kitty is translucent
return {
	{
		"vague-theme/vague.nvim",
		lazy = true,
		opts = {
			transparent = true,
			bold = true,
			italic = true,
		},
	},

	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		opts = {
			flavour = "macchiato",
			transparent_background = true,
			float = { transparent = true },
		},
	},

	{
		"folke/tokyonight.nvim",
		lazy = true,
		opts = {
			style = "night",
			transparent = true,
			styles = { floats = "transparent", sidebars = "transparent" },
		},
	},

	{ "RRethy/base16-nvim", lazy = true },
}
