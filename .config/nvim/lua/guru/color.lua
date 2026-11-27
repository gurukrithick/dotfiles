local M = {}

function M.get(group, attr)
	local value = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
	return value and ("#%06x"):format(value) or nil
end

local function channels(hex)
	return tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
end

function M.mix(a, b, t)
	local ar, ag, ab = channels(a)
	local br, bg, bb = channels(b)
	local function at(x, y)
		return math.floor(x + (y - x) * t + 0.5)
	end
	return ("#%02x%02x%02x"):format(at(ar, br), at(ag, bg), at(ab, bb))
end

local function luminance(hex)
	local sum = 0
	for i, c in ipairs({ channels(hex) }) do
		c = c / 255
		sum = sum + ({ 0.2126, 0.7152, 0.0722 })[i] * (c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4)
	end
	return sum
end

local function contrast(a, b)
	local x, y = luminance(a), luminance(b)
	return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

function M.readable(color, text, bg, ratio)
	for t = 0, 1, 0.05 do
		local c = M.mix(color, text, t)
		if contrast(c, bg) >= ratio then
			return c
		end
	end
	return text
end

function M.surface()
	return M.get("CursorLine", "bg") or M.get("Visual", "bg") or "#2a2a37"
end

return M
