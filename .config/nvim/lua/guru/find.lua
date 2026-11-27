local M = {}

-- fff keeps its index in memory, so not for all of $HOME; fzf-lua lists there
function M.files()
	if vim.uv.cwd() == vim.env.HOME then
		require("fzf-lua").files()
	else
		require("fff").find_files()
	end
end

return M
