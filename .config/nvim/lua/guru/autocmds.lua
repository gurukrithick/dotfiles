local augroup = function(name)
	return vim.api.nvim_create_augroup("guru_" .. name, { clear = true })
end

-- main branch has no highlight module; indent stays off, nvim-treesitter's indentexpr is ~685ms per line
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("treesitter"),
	callback = function(args)
		local ft = vim.bo[args.buf].filetype
		if ft == "" then
			return
		end

		local lang = vim.treesitter.language.get_lang(ft)
		if not lang then
			return
		end

		local ok, added = pcall(vim.treesitter.language.add, lang)
		if not ok or not added then
			return
		end

		pcall(vim.treesitter.start, args.buf, lang)
	end,
})

-- lsp keymaps
vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup("lsp_attach"),
	callback = function(event)
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, silent = true, desc = "LSP: " .. desc })
		end

		map("n", "gd", vim.lsp.buf.definition, "Go to definition")
		map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
		map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
		map("n", "K", vim.lsp.buf.hover, "Hover documentation")
		-- no <C-k> here: buffer-local, would shadow tmux-navigator; blink owns it in insert
		map("n", "<leader>D", vim.lsp.buf.type_definition, "Type definition")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
		map("n", "<leader>d", vim.diagnostic.open_float, "Show diagnostic")

		-- goto_prev/goto_next deprecated in 0.11
		map("n", "[d", function()
			vim.diagnostic.jump({ count = -1, float = true })
		end, "Previous diagnostic")
		map("n", "]d", function()
			vim.diagnostic.jump({ count = 1, float = true })
		end, "Next diagnostic")
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("yank_highlight"),
	callback = function()
		vim.hl.on_yank({ timeout = 150 })
	end,
})

-- per colorscheme load, a one-off got wiped on theme reload
vim.api.nvim_create_autocmd("ColorScheme", {
	group = augroup("highlights"),
	callback = function()
		local color = require("guru.color")
		local text = color.get("Normal", "fg")
		if not text then
			return
		end
		local surface = color.surface()
		local function set(group, opts)
			vim.api.nvim_set_hl(0, group, opts)
		end
		local function dim(group, ratio)
			return color.readable(color.get(group, "fg") or text, text, surface, ratio)
		end

		local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
		comment.fg = dim("Comment", 4.5)
		set("Comment", comment)
		local number = dim("LineNr", 2.6)
		for _, group in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow" }) do
			set(group, { fg = number })
		end

		set("OilHidden", { fg = comment.fg })
		set("OilDirHidden", { fg = color.mix(color.get("Directory", "fg") or text, comment.fg, 0.5) })

		set("StatusLine", { fg = text, bg = "NONE" })
		set("StatusLineNC", { fg = number, bg = "NONE" })
		set("WinSeparator", { fg = surface, bg = "NONE" })

		set("MiniIndentscopeSymbol", { fg = number })
		set("MiniStarterHeader", { fg = color.get("Constant", "fg") })
		set("MiniStarterSection", { fg = require("guru.statusline").accent(), bold = true })
		set("MiniStarterItem", { fg = text })
		set("MiniStarterItemPrefix", { fg = color.get("String", "fg"), bold = true })
		set("MiniStarterItemBullet", { fg = number })
		set("MiniStarterQuery", { fg = color.get("String", "fg"), bold = true })
		set("MiniStarterCurrent", { bold = true })
		set("MiniStarterInactive", { fg = number })
		set("MiniStarterFooter", { fg = comment.fg, italic = true })
	end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
	group = augroup("last_position"),
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})
