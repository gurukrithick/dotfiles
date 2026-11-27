-- The start screen: a warm drink, a greeting for the time of day, recent files.
local M = {}

local cup = {
	"   )  (   ",
	"  (    )  ",
	"╭───────╮ ",
	"│       ├╮",
	"│       ├╯",
	"╰───────╯ ",
}

local function greeting()
	local hour = tonumber(os.date("%H"))
	local part = hour >= 5 and hour < 12 and "good morning"
		or hour >= 12 and hour < 17 and "good afternoon"
		or hour >= 17 and hour < 21 and "good evening"
		or "up late"
	return part .. ", " .. (vim.env.USER or "friend")
end

function M.opts()
	local starter = require("mini.starter")
	local function pick(name, command)
		return { name = name, action = command, section = "Start" }
	end
	return {
		evaluate_single = true,
		header = function()
			local hello = greeting()
			local lines = {}
			for _, line in ipairs(cup) do
				lines[#lines + 1] = (" "):rep(math.max(0, math.floor((#hello - 10) / 2))) .. line
			end
			return table.concat(lines, "\n") .. "\n\n" .. hello
		end,
		items = {
			function()
				local items = starter.sections.recent_files(5, true, false)()
				for _, item in ipairs(items) do
					item.section = "Recent here"
				end
				return items[1] and items[1].action ~= "" and items or {}
			end,
			{
				name = "find file",
				action = function()
					require("guru.find").files()
				end,
				section = "Start",
			},
			pick("search text", "FzfLua live_grep"),
			pick("projects", "FzfLua zoxide"),
			{
				name = "last session",
				action = function()
					require("persistence").load({ last = true })
				end,
				section = "Start",
			},
			pick("new file", "enew"),
			pick("quit", "qall"),
		},
		footer = function()
			return os.date("%A, %d %B")
		end,
		content_hooks = {
			starter.gen_hook.adding_bullet("  "),
			starter.gen_hook.aligning("center", "center"),
		},
	}
end

return M
