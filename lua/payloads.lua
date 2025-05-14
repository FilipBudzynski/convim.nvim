Payload = {}

Payload.PAYLOAD_BUFFER_TYPE = "buffer"
Payload.PAYLOAD_CURSOR_TYPE = "cursor"
Payload.BYTE_CHANGE = "byte"
Payload.LINE_CHANGE = "line"

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
---@field type string,
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

function Payload:tostring()
	for _, v in ipairs(self) do
		print(v)
	end
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

---@param buf integer
---@param changedtick integer,
---@param sr integer,
---@param sc integer,
---@param offset integer,
---@param old_er integer,
---@param old_ec integer,
---@param old_end_byte integer,
---@param new_er integer,
---@param new_ec integer,
---@param new_end_byte integer
---@return ChangePayload
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
	-- TODO: if more than one rows has been changed,
	-- the whole lines should be rewritten

	local payload = {
		type = "",
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
		new_content = {},
	}

	local content = {}
	if new_er > 0 then
		content = vim.api.nvim_buf_get_lines(buf, sr, sr + new_er, false)
		payload.type = Payload.LINE_CHANGE
	else
		content = vim.api.nvim_buf_get_text(buf, sr, sc, sr, sc + new_end_byte, {})
		payload.type = Payload.BYTE_CHANGE
	end

	payload.new_content = content

	-- debug
	for _, line in ipairs(content) do
		print(line)
	end

	setmetatable(payload, self)
	return payload
end

local factory = {
	buffer = new_buffer,
	cursor = new_cursor,
}

---@param choice string describes the paylaod type "buffer" | "cursor"
function Payload:new(choice)
	if factory[choice] then
		local payload = factory[choice]()
		return setmetatable(payload, self)
	end
end

return Payload
