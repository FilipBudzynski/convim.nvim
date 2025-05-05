local M = {}

local Buffer = vim.api.nvim_create_buf(true, false)
local ExtmarkId = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

---@param payload BufferPayload
function M.set_buffer(payload)
	if payload.buffer_name then
		vim.api.nvim_buf_set_name(Buffer, "[peer] " .. payload.buffer_name)
	else
		vim.api.nvim_buf_set_name(Buffer, "[peer] unnamed buffer")
	end

	vim.api.nvim_buf_set_lines(Buffer, 0, -1, true, payload.lines)
	vim.api.nvim_set_current_buf(Buffer)

	local filetype = vim.filetype.match({ filename = payload.buffer_name })
	if filetype then
		vim.bo[Buffer].filetype = filetype
	else
		print("Could not determine filetype for:", payload.buffer_name)
	end
end

---@param cursor CursorPayload
function M.draw_cursor(cursor)
	if ExtmarkId then
		vim.api.nvim_buf_del_extmark(0, ns, ExtmarkId)
	end

	ExtmarkId = vim.api.nvim_buf_set_extmark(0, ns, cursor.line - 1, cursor.col, {
		end_col = cursor.col + 1,
		virt_text_pos = "overlay",
		hl_group = "Cursor",
		hl_mode = "combine",
	})
end

---@param line_payload InputPayload
function M.put(line_payload)
	vim.api.nvim_buf_set_lines(0, line_payload.row_nr-1, line_payload.row_nr, false, line_payload.content)
	-- vim.api.nvim_buf_set_text(
	-- 	0,
	-- 	line_payload.row_nr,
	-- 	line_payload.col_nr,
	-- 	line_payload.row_nr,
	-- 	line_payload.col_nr,
	-- 	line_payload.content
	-- )
end

function M.remove_cursor()
	if ExtmarkId then
		vim.api.nvim_buf_del_extmark(0, ns, ExtmarkId)
	end
end

return M
