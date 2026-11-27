-- overrides only, upstream lsp/ files supply cmd/filetypes/root_markers; keymaps in autocmds.lua

return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"saghen/blink.cmp",
		"b0o/schemastore.nvim",
	},
	config = function()
		vim.diagnostic.config({
			virtual_text = false,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "\u{f0159}",
					[vim.diagnostic.severity.WARN] = "\u{f0028}",
					[vim.diagnostic.severity.HINT] = "\u{f0335}",
					[vim.diagnostic.severity.INFO] = "\u{f02fd}",
				},
			},
			underline = true,
			severity_sort = true,
			float = { source = true },
			update_in_insert = false,
		})

		vim.lsp.config("*", {
			capabilities = require("blink.cmp").get_lsp_capabilities({}, true),
		})

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
					workspace = { checkThirdParty = false },
					telemetry = { enable = false },
				},
			},
		})

		vim.lsp.config("rust_analyzer", {
			settings = {
				["rust-analyzer"] = {
					check = { command = "clippy" },
					cargo = { allFeatures = true },
				},
			},
		})

		vim.lsp.config("ts_ls", {
			settings = {
				typescript = {
					inlayHints = {
						includeInlayParameterNameHints = "all",
						includeInlayFunctionParameterTypeHints = true,
					},
				},
			},
		})

		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
					},
				},
			},
		})

		vim.lsp.config("clangd", {
			cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
		})

		vim.lsp.config("eslint", {
			settings = { workingDirectories = { mode = "auto" } },
		})

		vim.lsp.config("jsonls", {
			settings = {
				json = {
					schemas = require("schemastore").json.schemas(),
					validate = { enable = true },
				},
			},
		})

		vim.lsp.config("yamlls", {
			settings = {
				yaml = {
					schemaStore = { enable = false, url = "" },
					schemas = require("schemastore").yaml.schemas(),
				},
			},
		})

		-- rust_analyzer comes from rustup, enable by hand
		vim.lsp.enable("rust_analyzer")
	end,
}
