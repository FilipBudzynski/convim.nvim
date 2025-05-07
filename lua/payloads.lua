Payload = {}

Payload.PAYLOAD_BUFFER_TYPE = "buffer"
Payload.PAYLOAD_INPUT_TYPE = "input"
Payload.PAYLOAD_CURSOR_TYPE = "cursor"
Payload.PAYLOAD_CHANGE_TYPE = "change"

local CURRENT_BUFFER = 0
local WHOLE_BUFFER = { 0, -1 }

---@class BufferPayload
---@field type string
---@field lines string[]
---@field buffer_name string

---@class CursorPayload
---@field type string
---@field line integer
---@field col integer

---@class InputPayload
---@field type string
---@field row_nr integer
---@field col_nr integer
---@field content string[]

---@class ChangePayload
---@field buf integer,
---@field changedtick integer,
---@field sr integer,
---@field sc integer,
---@field offset integer,
---@field old_er integer,
---@field old_ec integer,
---@field old_end_byte integer,
---@field new_er integer,
---@field new_ec integer,
---@field new_end_byte integer
---@field new_content string[]

Payload.__index = Payload

function Payload.encode(o)
	return vim.fn.json_encode(o) .. "\n"
end

---@return BufferPayload
local function new_buffer()
	local lines = vim.api.nvim_buf_get_lines(CURRENT_BUFFER, WHOLE_BUFFER[1], WHOLE_BUFFER[2], false)
	local bufname = vim.api.nvim_buf_get_name(CURRENT_BUFFER)

	return {
		type = Payload.PAYLOAD_BUFFER_TYPE,
		lines = lines,
		buffer_name = bufname,
	}
end

---@return CursorPayload
local function new_cursor()
	local pos = vim.api.nvim_win_get_cursor(CURRENT_BUFFER)
	return {
		type = Payload.PAYLOAD_CURSOR_TYPE,
		line = pos[1],
		col = pos[2],
	}
end

---@return InputPayload
local function new_input()
	local pos = vim.api.nvim_win_get_cursor(CURRENT_BUFFER)
	local line = vim.api.nvim_get_current_line()
	local content = line[pos[2]]
	print(content)

	return {
		type = Payload.PAYLOAD_INPUT_TYPE,
		row_nr = pos[1],
		col_nr = pos[2],
		content = { content },
	}
end

function Payload:new_change(
	buf,
	changedtick,
	sr,
	sc,
	offset,
	old_er,
	old_ec,
	old_end_byte,
	new_er,
	new_ec,
	new_end_byte
)
	-- print("start row: " .. sr)
	-- print("old end row: " .. old_er)
	-- print("new end row: " .. new_er)
	-- print("<<<<<<<<<<<<")
	-- print("start col: " .. sc)
	-- print("old end col: " .. old_ec)
	-- print("new end col: " .. new_ec)
	-- print("buf: " .. buf)
	if new_er == 0 then
		new_er = sr
	end
	local content = vim.api.nvim_buf_get_text(buf, sr, sc, new_er, new_ec, {})
	local o = {
		type = Payload.PAYLOAD_CHANGE_TYPE,
		buf = buf,
		changedtick = changedtick,
		sr = sr,
		sc = sc,
		offset = offset,
		old_er = old_er,
		old_ec = old_ec,
		old_end_byte = old_end_byte,
		new_er = new_er,
		new_ec = new_ec,
		new_end_byte = new_end_byte,
		new_content = content,
	}
	setmetatable(o, self)
	return o
end

local factory = {
	buffer = new_buffer,
	cursor = new_cursor,
	input = new_input,
}

---@param choice string describes the paylaod type "buffer" | "cursor" | "input"
function Payload:new(choice)
	if factory[choice] then
		local payload = factory[choice]()
		return setmetatable(payload, self)
	end
end

return Payload
