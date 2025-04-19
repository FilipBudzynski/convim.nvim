local M = {}
local tcp = require("client")
local uv = vim.uv

local function prepare_buffer_payload()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local bufname = vim.api.nvim_buf_get_name(0)

	local payload = {
		type = "buffer",
		lines = lines,
		bufname = bufname,
	}

	local json = vim.fn.json_encode(payload) .. "\n"
	return json
end

M.start = function(opts)
	opts = opts or {}

	vim.api.nvim_create_user_command("StartConvimServer", function()
		local file_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
		local server_dir = vim.fs.normalize(file_dir .. "../server")

		vim.system({ "go", "run", "." }, {
			cwd = server_dir,
			stdout = function(_, data)
				if data then
					print("[GoServer] " .. data)
				end
			end,
			stderr = function(_, data)
				if data then
					vim.notify("[GoServer ERROR] " .. vim.log.levels.ERROR .. data)
				end
			end,
		})
	end, {})

	vim.api.nvim_create_user_command("StartSession", function()
		---@type uv.uv_tcp_t | nil
		local client = tcp.connect("127.0.0.1", 9999)
		if not client then
			return
		end
		-- send the whole buffer
		local payload = prepare_buffer_payload()
		client:write(payload)

		vim.api.nvim_create_autocmd("CursorMoved", {
			callback = tcp.send_cursor,
			group = vim.api.nvim_create_augroup("GoServerCursorSync", { clear = true }),
		})
	end, {})

	vim.api.nvim_create_user_command("ConnectToServer", function()
		tcp.connect("127.0.0.1", 9999)
		vim.api.nvim_create_autocmd("CursorMoved", {
			callback = tcp.send_cursor,
			group = vim.api.nvim_create_augroup("GoServerCursorSync", { clear = true }),
		})
	end, {})

	vim.api.nvim_create_user_command("Disconnect", function()
		tcp.disconnect()
	end, {})
end

return M
