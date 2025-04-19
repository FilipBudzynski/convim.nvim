local M = {}
local uv = vim.uv
local ui = require("ui")

local client = nil
local is_connected = false

PAYLOAD_BUFFER_TYPE = "buffer"
PAYLOAD_CURSOR_TYPE = "cursor"

function M.send_cursor()
	if not client or not is_connected then
		return
	end

	local line = vim.api.nvim_get_current_line()
	if line == "" then
		return
	end

	local pos = vim.api.nvim_win_get_cursor(0)

	---@type CursorPayload
	local payload = {
		type = "cursor",
		line = pos[1],
		col = pos[2],
	}
	local cursor_payload = vim.fn.json_encode(payload) .. "\n"
	client:write(cursor_payload)
end

---@param host string
---@param port integer
---@return uv.uv_tcp_t | nil
function M.connect(host, port)
	if client and is_connected then
		vim.notify("Already connected to TCP server", vim.log.levels.INFO)
		return nil
	end

	client = uv.new_tcp()
	if not client then
		print("new_tcp returned nil")
		return nil
	end

	client:connect(host, port, function(err)
		vim.schedule(function()
			if err then
				vim.notify("TCP connection failed: " .. err, vim.log.levels.ERROR)
				is_connected = false
				return
			end

			is_connected = true
			vim.notify("Connected to TCP server at " .. host .. ":" .. port)

			client:read_start(function(err, data)
				assert(not err, err)
				if data then
					vim.schedule(function()
						for line in data:gmatch("[^\r\n]+") do
							local payload = vim.fn.json_decode(line)
							if payload.type == "buffer" then
								local buffer = payload
								ui.set_buffer(buffer)
							elseif payload.type == "cursor" then
								---@type CursorPayload
								local cursor = payload
								ui.draw_cursor(cursor)
							else
								print("Failed to decode or unexpected payload: ", vim.inspect(line))
							end
						end
					end)
				end
			end)
		end)
	end)

	return client
end

function M.disconnect()
	if client and is_connected then
		client:shutdown()
		client:close()
		client = nil
		is_connected = false
		ui.remove_cursor()
		vim.notify("Disconnected from TCP server")
	end
end

return M
