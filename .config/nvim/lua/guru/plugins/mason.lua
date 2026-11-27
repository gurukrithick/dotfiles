
return {
	{
		"mason-org/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonToolsInstall", "MasonToolsUpdate" },
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		},
	},

	{
		"mason-org/mason-lspconfig.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			-- stylua --lsp would be auto-enabled and fight conform
			automatic_enable = { exclude = { "stylua" } },
			ensure_installed = {
				"lua_ls",
				"gopls",
				"ts_ls",
				"eslint",
				"tailwindcss",
				"prismals",
				"html",
				"cssls",
				"svelte",
				"pyright",
				"ruff",
				"jsonls",
				"yamlls",
				"taplo",
				"marksman",
				"bashls",
				"clangd",
				"jdtls",
				"dockerls",
				"docker_compose_language_service",
			},
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
		dependencies = { "mason-org/mason.nvim" },
		opts = {
			ensure_installed = {
				"stylua",
				"prettier",
				"ruff",
				"clang-format",
				"google-java-format",
				"gofumpt",
				"goimports",
				"shfmt",
				"shellcheck",
				"sqlfluff",
			},
			-- network round-trip on every startup, :MasonToolsUpdate by hand
			auto_update = false,
			run_on_start = false,
		},
	},
}
