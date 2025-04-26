local Payload = {}

---@class InputPayload
---@field type string
---@field line_nr integer
---@field content string

Payload.InputPayload = {}
Payload.InputPayload.__index = Payload.InputPayload

---@param content string --the line of the content that is inputed
---@param line_nr integer -- which line have been changed
function Payload.InputPayload:new(content, line_nr)
	return setmetatable({
		type = "one_line_input",
		line_nr = line_nr,
		content = content,
	}, self)
end

---@class BufferPayload
---@field type string
---@field lines string[]
---@field bufname string

---@class CursorPayload
---@field type string
---@field line integer
---@field col integer

Payload.CursorPayload = {}
Payload.CursorPayload.__index = Payload.CursorPayload

---@param line_nr integer -- number of the line where the cursor is at
---@param col_nr integer -- number of the column where the cursors is at
function Payload.CursorPayload:new(line_nr, col_nr)
	return setmetatable({
		type = "cursor",
		line = line_nr,
		col = col_nr,
	}, self)
end

---@return string
function Payload.CursorPayload:encode()
	local cursor_payload = vim.fn.json_encode(self) .. "\n"
	return cursor_payload
end

return Payload
