local M = {}

local ExtmarkId = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

---@param payload BufferPayload
---@return integer
function M.set_buffer(payload)
	local buffer = 0
	if payload.buffer_name then
		vim.api.nvim_buf_set_name(buffer, "[peer] " .. payload.buffer_name)
	else
		vim.api.nvim_buf_set_name(buffer, "[peer] unnamed buffer")
	end

	local filetype = vim.filetype.match({ filename = payload.buffer_name })
	if filetype then
		vim.bo[buffer].filetype = filetype
	else
		print("Could not determine filetype for:", payload.buffer_name)
	end

	vim.api.nvim_buf_set_lines(buffer, 0, -1, true, payload.lines)

	return buffer
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

---@param change ChangePayload
function M.put(change)
	if change.type == Payload.BYTE_CHANGE then
		vim.api.nvim_buf_set_text(
			0,
			change.sr,
			change.sc,
			change.sr,
			change.sc + change.old_ec,
			change.new_content
		)
	end
end

function M.remove_cursor()
	if ExtmarkId then
		vim.api.nvim_buf_del_extmark(0, ns, ExtmarkId)
	end
end

return M
