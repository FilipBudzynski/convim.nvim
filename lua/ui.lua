local M = {}

local Buffer = vim.api.nvim_create_buf(true, false)
local ExtmarkId = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

---@param payload BufferPayload
function M.set_buffer(payload)
	if payload.bufname then
		vim.api.nvim_buf_set_name(Buffer, "[peer] " .. payload.bufname)
	else
		vim.api.nvim_buf_set_name(Buffer, "[peer] unnamed buffer")
	end

	vim.api.nvim_buf_set_lines(Buffer, 0, -1, true, payload.lines)
	vim.api.nvim_set_current_buf(Buffer)

	local filetype = vim.filetype.match({ filename = payload.bufname })
	if filetype then
		vim.bo[Buffer].filetype = filetype
	else
		print("Could not determine filetype for:", payload.bufname)
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

function M.remove_cursor()
	if ExtmarkId then
		vim.api.nvim_buf_del_extmark(0, ns, ExtmarkId)
	end
end

return M
