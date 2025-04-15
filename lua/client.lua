local M = {}
local uv = vim.uv

local client = nil
local is_connected = false
local extmark_id = nil
local ns = vim.api.nvim_create_namespace("convim_plugin")

PAYLOAD_BUFFER_TYPE = "buffer"
PAYLOAD_CURSOR_TYPE = "cursor"

---@class CursorPayload
---@field type string
---@field line integer
---@field col integer

---@class BufferPayload
---@field type string
---@field lines string[]
---@field bufname string

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

---@param cursor CursorPayload
function M.draw_cursor(cursor)
	if extmark_id then
		vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
	end

	extmark_id = vim.api.nvim_buf_set_extmark(0, ns, cursor.line - 1, cursor.col, {
		end_col = cursor.col + 1,
		virt_text_pos = "overlay",
		hl_group = "Cursor",
		hl_mode = "combine",
	})
end

---@param payload BufferPayload
function M.render_remote_buffer(payload)
	local buf = vim.api.nvim_create_buf(true, false)
	if payload.bufname then
		vim.api.nvim_buf_set_name(buf, "[peer] " .. payload.bufname)
	else
		vim.api.nvim_buf_set_name(buf, "[peer] unnamed buffer")
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, payload.lines)
	vim.api.nvim_set_current_buf(buf)

	local filetype = vim.filetype.match({ filename = payload.bufname })
	if filetype then
		vim.bo[buf].filetype = filetype
	else
		print("Could not determine filetype for:", payload.bufname)
	end
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
					vim.schedule(function()
						for line in data:gmatch("[^\r\n]+") do
							local payload = vim.fn.json_decode(line)
							if payload.type == "buffer" then
								---@type BufferPayload
								local buffer = payload
								M.render_remote_buffer(buffer)
							elseif payload.type == "cursor" then
								---@type CursorPayload
								local cursor = payload
								M.draw_cursor(cursor)
							else
								print("Failed to decode or unexpected payload: ", vim.insepct(line))
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
	if client then
		client:shutdown(function()
			client:close()
			client = nil
			is_connected = false
			vim.notify("Disconnected from TCP server")
		end)
		if extmark_id then
			vim.api.nvim_buf_del_extmark(0, ns, extmark_id)
		end
	end
end

return M
