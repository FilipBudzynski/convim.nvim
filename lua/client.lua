local M = {}
local uv = vim.uv
local ui = require("ui")
require("payloads")

local Client = nil
local ignore = {}

local function handle_byte_payload(payload)
	local tick = vim.api.nvim_buf_get_changedtick(0) + 1
	ignore[tick] = true
	ui.put(payload)
end

local handle_payload = {
	buffer = ui.set_buffer,
	cursor = ui.draw_cursor,
	byte = handle_byte_payload,
	--line = handle_line_payload,
}

-- the string "bytes"
-- buffer id
-- b:changedtick
-- start row of the changed text (zero-indexed)
-- start column of the changed text
-- byte offset of the changed text (from the start of the buffer)
-- old end row of the changed text (offset from start row)
-- old end column of the changed text (if old end row = 0, offset from start column)
-- old end byte length of the changed text
-- new end row of the changed text (offset from start row)
-- new end column of the changed text (if new end row = 0, offset from start column)
-- new end byte length of the changed text
function M.send_byte_change(
	_,
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
	if not Client then
		return
	end

	if ignore[changedtick] then
		ignore[changedtick] = nil
		return
	end

	Client:write(
		Payload:new_change(buf,
            changedtick,
            sr,
            sc,
            offset,
            old_er,
            old_ec,
            old_end_byte,
            new_er,
            new_ec,
            new_end_byte):encode()
	)
end

---@param host string
---@param port integer
---@return uv.uv_tcp_t | nil
function M.connect(host, port)
	if Client then
		vim.notify("Already connected to TCP server", vim.log.levels.INFO)
		return nil
	end

	Client = uv.new_tcp()
	if not Client then
		print("new_tcp returned nil")
		return nil
	end

	Client:connect(host, port, function(err)
		vim.schedule(function()
			if err then
				vim.notify("TCP connection failed: " .. err, vim.log.levels.ERROR)
				return
			end

			vim.notify("Connected to TCP server at " .. host .. ":" .. port)

			Client:read_start(function(err, data)
				assert(not err, err)
				if not data then
					print("LOG: no data received")
					return
				end

				vim.schedule(function()
					for line in data:gmatch("[^\r\n]+") do
						local payload = vim.fn.json_decode(line)

						if not handle_payload[payload.type] then
							print('LOG: unsupported payload type "' .. payload.type .. '"')
							return
						end
						handle_payload[payload.type](payload)
					end
				end)
			end)
		end)
	end)

	return Client
end

function M.send_current_buffer()
	if not Client then
		print("No client connected to the server...")
		return
	end

	Client:write(Payload:new("buffer"):encode())
end

function M.send_cursor()
	local line = vim.api.nvim_get_current_line()
	if not Client or line == "" then
		return
	end

	Client:write(Payload:new("cursor"):encode())
end

function M.disconnect()
	if Client then
		Client:shutdown()
		Client:close()
		Client = nil
		ui.remove_cursor()
		vim.notify("Disconnected from TCP server")
	end
end

return M
