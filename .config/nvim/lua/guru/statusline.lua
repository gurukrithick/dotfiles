local color = require("guru.color")
local M = {}

-- accent where the scheme's Function differs
local accents = {
	vague = "#b8c7bc", -- sage; vague's own Function reads as an alert
	["catppuccin-macchiato"] = "#c6a0f6", -- mauve
}

function M.accent()
	return accents[vim.g.colors_name] or color.get("Function", "fg") or "#cdcdcd"
end

function M.theme()
	local text = color.get("Normal", "fg") or "#cdcdcd"
	local surface = color.surface()
	local dim = color.readable(color.get("Comment", "fg") or text, text, surface, 4.5)
	local ink = color.mix(surface, "#000000", 0.45)
	local function mode(accent)
		return {
			a = { fg = ink, bg = accent, gui = "bold" },
			b = { fg = text, bg = surface },
			c = { fg = dim, bg = "NONE" },
			x = { fg = dim, bg = "NONE" },
			y = { fg = text, bg = surface },
			z = { fg = ink, bg = accent, gui = "bold" },
		}
	end
	local function fg(group)
		return color.get(group, "fg") or text
	end
	return {
		normal = mode(M.accent()),
		insert = mode(fg("String")),
		visual = mode(vim.g.colors_name == "catppuccin-macchiato" and fg("Function") or fg("Statement")),
		replace = mode(fg("DiagnosticError")),
		command = mode(fg("Constant")),
		terminal = mode(fg("DiagnosticWarn")),
		inactive = {
			a = { fg = dim, bg = "NONE" },
			b = { fg = dim, bg = "NONE" },
			c = { fg = dim, bg = "NONE" },
		},
	}
end

local left, right = "\u{e0b6}", "\u{e0b4}"
local icons = {
	n = "\u{f04b2}", -- sleep: resting between edits
	i = "\u{f03eb}", -- pencil
	v = "\u{f0485}", -- select
	R = "\u{f0450}", -- refresh
	c = "\u{f018d}", -- console
	t = "\u{f018d}",
}

local function mode_label(name)
	local key = vim.fn.mode():sub(1, 1)
	if key == "V" or key == "\22" or key == "s" or key == "S" then
		key = "v"
	end
	return (icons[key] or icons.n) .. " " .. name:lower()
end

local function folder()
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" or vim.bo.buftype ~= "" then
		return ""
	end
	local dir = vim.fn.fnamemodify(name, ":~:.:h")
	if dir == "." then
		return ""
	end
	return (vim.o.columns < 120 and vim.fn.pathshorten(dir) or dir):gsub("%%", "%%%%") .. "/"
end

local function file_icon()
	local name = vim.api.nvim_buf_get_name(0)
	return name ~= "" and (require("mini.icons").get("file", name)) or ""
end

local function recording()
	local reg = vim.fn.reg_recording()
	return reg ~= "" and "\u{f044a} @" .. reg or ""
end

local function sky()
	local hour = tonumber(os.date("%H"))
	if hour >= 5 and hour < 11 then
		return "\u{f0176}"
	elseif hour >= 11 and hour < 17 then
		return "\u{f0599}"
	elseif hour >= 17 and hour < 20 then
		return "\u{f059a}"
	end
	return "\u{f0594}"
end

local helpers = { tailwindcss = true, eslint = true }

local function servers()
	local main
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		if not helpers[client.name] then
			main = main or client.name
		end
	end
	return main or ""
end

local function wide(columns)
	return function()
		return vim.o.columns >= columns
	end
end

local function pill(component)
	component.separator = { left = left, right = right }
	return component
end

M.sections = {
	lualine_a = { pill({ "mode", fmt = mode_label, padding = { left = 1, right = 1 } }) },
	lualine_b = {},
	lualine_c = {
		{ "branch", icon = "\u{e725}", padding = { left = 2, right = 1 }, cond = wide(80) },
		{
			"diff",
			symbols = { added = "\u{f0415} ", modified = "\u{f03eb} ", removed = "\u{f0374} " },
			source = function()
				local git = vim.b.gitsigns_status_dict
				if git then
					return { added = git.added, modified = git.changed, removed = git.removed }
				end
			end,
			cond = wide(110),
		},
		{
			file_icon,
			padding = { left = 2, right = 1 },
			color = function()
				local _, group = require("mini.icons").get("file", vim.api.nvim_buf_get_name(0))
				return { fg = color.get(group, "fg") }
			end,
		},
		{ folder, padding = 0, cond = wide(80) },
		{
			"filename",
			cond = function()
				return vim.bo.buftype == "" or vim.api.nvim_buf_get_name(0) ~= ""
			end,
			padding = { left = 0, right = 1 },
			symbols = { modified = "\u{f444}", readonly = "\u{f033e}", unnamed = "new file" },
			color = function()
				return { fg = color.get("Normal", "fg") }
			end,
		},
		{
			recording,
			color = function()
				return { fg = color.get("DiagnosticError", "fg") }
			end,
		},
	},
	lualine_x = {
		{
			"diagnostics",
			sources = { "nvim_diagnostic" },
			sections = { "error", "warn" },
			symbols = { error = "\u{f0159} ", warn = "\u{f0028} " },
		},
		{ servers, icon = "\u{f032a}", cond = wide(110) },
		{ sky, padding = { left = 1, right = 2 }, cond = wide(80) },
	},
	lualine_y = {},
	lualine_z = { pill({ "location", fmt = vim.trim, padding = { left = 1, right = 1 } }) },
}

local function label(filetypes, icon, text)
	return {
		filetypes = filetypes,
		sections = {
			lualine_a = {
				pill({
					function()
						return icon .. " " .. (type(text) == "function" and text() or text)
					end,
					padding = { left = 1, right = 1 },
				}),
			},
		},
	}
end

M.oil = {
	filetypes = { "oil" },
	sections = {
		lualine_a = {
			pill({
				function()
					local dir = require("oil").get_current_dir()
					return "\u{f0770} " .. (dir and vim.fn.fnamemodify(dir, ":~") or vim.api.nvim_buf_get_name(0))
				end,
				padding = { left = 1, right = 1 },
			}),
		},
		lualine_b = {},
		lualine_c = {
			{ "branch", icon = "\u{e725}", padding = { left = 2, right = 1 }, cond = wide(80) },
			{
				function()
					return vim.bo.modified and "\u{f444} unsaved" or ""
				end,
				color = function()
					return { fg = color.get("DiagnosticWarn", "fg") }
				end,
			},
		},
		lualine_x = { { sky, padding = { left = 1, right = 2 }, cond = wide(80) } },
		lualine_y = {},
		lualine_z = {
			pill({
				function()
					local items = 0
					for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
						if line ~= "" and not line:match("%.%./?$") then
							items = items + 1
						end
					end
					return items == 1 and "1 item" or items .. " items"
				end,
				padding = { left = 1, right = 1 },
			}),
		},
	},
}

M.extensions = {
	M.oil,
	label({ "fzf", "fff_file_info", "fff_input", "fff_list", "fff_preview" }, "\u{f0349}", "find"),
	label({ "codediff-explorer" }, "\u{f02a2}", "review"),
	label({ "codediff-help" }, "\u{f02a2}", "review"),
	label({ "codediff-history" }, "\u{f02a2}", "history"),
	label({ "man" }, "\u{f02d6}", function()
		return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
	end),
	label({ "qf" }, "\u{f0279}", "quickfix"),
}

return M
