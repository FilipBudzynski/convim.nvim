local M = {}
local uv = vim.uv
local ui = require("ui")
local payloads = require("payload")

local Client = nil

PAYLOAD_BUFFER_TYPE = "buffer"
PAYLOAD_CURSOR_TYPE = "cursor"

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

	return Client
end

function M.send_cursor()
	if not Client then
		return
	end

	local line = vim.api.nvim_get_current_line()
	if line == "" then
		return
	end

	local pos = vim.api.nvim_win_get_cursor(0)

	local payload = payloads.CursorPayload:new(pos[1], pos[2])
	Client:write(payload:encode())
end

function M.send_current_buffer()
	if not Client then
		print("No client connected to the server...")
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local bufname = vim.api.nvim_buf_get_name(0)

	local payload = {
		type = "buffer",
		lines = lines,
		bufname = bufname,
	}

	local json_payload = vim.fn.json_encode(payload) .. "\n"
	Client:write(json_payload)
end

function M.send_char()
	if not Client then
		return
	end
	local line = vim.api.nvim_get_current_line()
	local pos = vim.api.nvim_win_get_cursor(0)
	local payload = payloads.InputPayload:new(line, pos[1])
	local json_payload = vim.fn.json_encode(payload) .. "\n"
	Client:write(json_payload)
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
