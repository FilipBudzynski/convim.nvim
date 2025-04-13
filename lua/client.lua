local M = {}
local uv = vim.uv

local client = nil
local is_connected = false
local extmark_id = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

---@class CursorPayload
---@field type string
---@field line integer
---@field col integer

---@param cursor CursorPayload
function M.draw_cursor(cursor)
	if extmark_id then
		vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
	end

	extmark_id = vim.api.nvim_buf_set_extmark(0, ns, cursor.line, cursor.col, {
		end_col = cursor.col + 1,
		virt_text_pos = "overlay",
		hl_group = "Cursor",
		hl_mode = "combine",
	})
end

---@class BufferPayload
---@field type "buffer"
---@field lines string[]
---@field bufname string

---@param payload BufferPayload
function Render_remote_buffer(payload)
	local buf = vim.api.nvim_create_buf(true, false)
	if payload.bufname then
		vim.api.nvim_buf_set_name(buf, "[peer] " .. payload.bufname)
	else
		vim.api.nvim_buf_set_name(buf, "[peer] unnamed buffer")
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload.lines)
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
		return
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
					print("raw data: ", data)
					for line in data:gmatch("[^\r\n]+") do
						local ok, payload = pcall(vim.fn.json_decode, line)
						if ok and payload.type == "buffer" then
							Render_remote_buffer(payload)
						end
					end
				end
			end)
		end)
	end)

	return client
end

function M.send_cursor()
	if not client or not is_connected then
		return
	end

	local pos = vim.api.nvim_win_get_cursor(0)

	---@type CursorPayload
	local payload = {
		type = "cursor",
		line = pos[1],
		col = pos[2],
	}
	-- local msg = string.format('{"line":%d,"col":%d}\n', pos[1], pos[2])
	local msg = vim.fn.json_encode(payload) .. "\n"
	client:write(msg)
end

function M.disconnect()
	if client then
		client:shutdown(function()
			client:close()
			client = nil
			is_connected = false
			vim.notify("Disconnected from TCP server")
		end)
	end
end

return M
