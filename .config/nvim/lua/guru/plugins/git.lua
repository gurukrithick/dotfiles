local gitsigns = {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "\u{258e}" },
			change = { text = "\u{258e}" },
			untracked = { text = "\u{258e}" },
		},
		on_attach = function(bufnr)
			local gs = require("gitsigns")

			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
			end

			map("n", "<leader>gb", function()
				gs.blame_line({ full = true })
			end, "Blame line")
			map("n", "<leader>gB", function()
				gs.toggle_current_line_blame()
			end, "Toggle line blame")
			map("n", "<leader>gd", gs.diffthis, "Diff this")
			map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
			map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
			map("n", "<leader>gS", gs.stage_hunk, "Stage hunk")

			map("n", "]h", function()
				gs.nav_hunk("next")
			end, "Next hunk")
			map("n", "[h", function()
				gs.nav_hunk("prev")
			end, "Previous hunk")
		end,
	},
}

return {
	gitsigns,

	{
		"esmuellert/codediff.nvim",
		cmd = "CodeDiff",
		opts = {
			diff = { filler_text = "\u{2571}" },
			explorer = { width = 34, line_stats = { enabled = true } },
		},
		keys = {
			{ "<leader>gv", "<cmd>CodeDiff<cr>", desc = "Review changes" },
			{ "<leader>gm", "<cmd>CodeDiff main...<cr>", desc = "Review branch against main" },
			{ "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "File history" },
		},
	},
}
