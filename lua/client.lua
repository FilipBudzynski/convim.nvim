local M = {}
local uv = vim.uv
local ui = require("ui")
require("payloads")

local Client = nil

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

							if payload.type == Payload.PAYLOAD_BUFFER_TYPE then
								local buffer = payload
								ui.set_buffer(buffer)
							elseif payload.type == Payload.PAYLOAD_INPUT_TYPE then
								---@type InputPayload
								local line_input = payload
								print(line_input.content)
								ui.put(line_input)
							elseif payload.type == Payload.PAYLOAD_CURSOR_TYPE then
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

function M.send_current_buffer()
	if not Client then
		print("No client connected to the server...")
		return
	end

	Client:write(Payload:new_buffer():encode())
end

function M.send_cursor()
	local line = vim.api.nvim_get_current_line()
	if not Client or line == "" then
		return
	end

	Client:write(Payload:new_cursor():encode())
end

function M.send_char()
	if not Client then
		return
	end

	local p = Payload:new_input()
	-- debug
	print(p.content[1])
	Client:write(p:encode())
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
