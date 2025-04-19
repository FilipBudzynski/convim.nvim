local M = {}

local extmark_id = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

---@class BufferPayload
---@field type string
---@field lines string[]
---@field bufname string

---@class CursorPayload
---@field type string
---@field line integer
---@field col integer

---@param payload BufferPayload
function M.set_buffer(payload)
	local buf = vim.api.nvim_create_buf(true, false)
	if payload.bufname then
		vim.api.nvim_buf_set_name(buf, "[peer] " .. payload.bufname)
	else
		vim.api.nvim_buf_set_name(buf, "[peer] unnamed buffer")
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload.lines)
	vim.api.nvim_set_current_buf(buf)

	local filetype = vim.filetype.match({ filename = payload.bufname })
	if filetype then
		vim.bo[buf].filetype = filetype
	else
		print("Could not determine filetype for:", payload.bufname)
	end
end

---@param cursor CursorPayload
function M.draw_cursor(cursor)
	if extmark_id then
		vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
	end

	extmark_id = vim.api.nvim_buf_set_extmark(0, ns, cursor.line - 1, cursor.col, {
		end_col = cursor.col + 1,
		virt_text_pos = "overlay",
		hl_group = "Cursor",
		hl_mode = "combine",
	})
end

function M.remove_cursor()
	if extmark_id then
		vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
	end
end

return M
