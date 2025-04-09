local M = {}

---@class Cursor
---@field line integer
---@field col integer

local cursor = { line = 0, col = 0 }
local extmark_id = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

local function draw_cursor()
	if extmark_id then
		vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
	end

	extmark_id = vim.api.nvim_buf_set_extmark(0, ns, cursor.line, cursor.col, {
		end_col = cursor.col + 1,
		virt_text_pos = "overlay",
		hl_group = "Cursor",
		hl_mode = "combine",
	})
end

M.start = function(opts)
	opts = opts or {}

	draw_cursor()

	-- move right
	vim.keymap.set("n", "9", function()
		local line = vim.api.nvim_buf_get_lines(0, cursor.line, cursor.line + 1, false)[1]
		if cursor.col < #line - 1 then
			cursor.col = cursor.col + 1
			draw_cursor()
		end
	end)

	-- move left
	vim.keymap.set("n", "6", function()
		if cursor.col > 0 then
			cursor.col = cursor.col - 1
			draw_cursor()
		end
	end)

	-- move up
	vim.keymap.set("n", "8", function()
		if cursor.line > 0 then
			cursor.line = cursor.line - 1
			local line = vim.api.nvim_buf_get_lines(0, cursor.line, cursor.line + 1, false)[1]
			if cursor.col > #line then
				cursor.col = #line
			end
			draw_cursor()
		end
	end)

	-- move down
	vim.keymap.set("n", "7", function()
		local line_count = vim.api.nvim_buf_line_count(0)
		if cursor.line < line_count - 1 then
			cursor.line = cursor.line + 1
			local line = vim.api.nvim_buf_get_lines(0, cursor.line, cursor.line + 1, false)[1]
			if cursor.col > #line then
				cursor.col = #line
			end
			draw_cursor()
		end
	end)
end

return M
