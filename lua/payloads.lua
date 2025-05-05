Payload = {}

Payload.PAYLOAD_BUFFER_TYPE = "buffer"
Payload.PAYLOAD_INPUT_TYPE = "input"
Payload.PAYLOAD_CURSOR_TYPE = "cursor"

local CURRENT_BUFFER = 0
local WHOLE_BUFFER = { 0, -1 }

---@class BufferPayload
---@field type string
---@field lines string[]
---@field buffer_name string
---@field encode function

---@class CursorPayload
---@field type string
---@field line integer
---@field col integer
---@field encode function

---@class InputPayload
---@field type string
---@field row_nr integer
---@field col_nr integer
---@field content string[]
---@field encode function

Payload.__index = Payload

function Payload.encode(o)
	return vim.fn.json_encode(o) .. "\n"
end

---@return BufferPayload
function Payload:new_buffer()
	local lines = vim.api.nvim_buf_get_lines(CURRENT_BUFFER, WHOLE_BUFFER[1], WHOLE_BUFFER[2], false)
	local bufname = vim.api.nvim_buf_get_name(CURRENT_BUFFER)

	local o = {
		type = self.PAYLOAD_BUFFER_TYPE,
		lines = lines,
		buffer_name = bufname,
	}
	setmetatable(o, self)
	return o
end

---@return CursorPayload
function Payload:new_cursor()
	local pos = vim.api.nvim_win_get_cursor(CURRENT_BUFFER)
	local o = {
		type = self.PAYLOAD_CURSOR_TYPE,
		line = pos[1],
		col = pos[2],
	}
	setmetatable(o, self)
	return o
end

function Payload:new_input()
	local pos = vim.api.nvim_win_get_cursor(CURRENT_BUFFER)
	local line = vim.api.nvim_get_current_line()

	return setmetatable({
		type = self.PAYLOAD_INPUT_TYPE,
		row_nr = pos[1],
		col_nr = pos[2],
		content = { line },
	}, self)
end

return Payload
