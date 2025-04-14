local M = {}
local tcp = require("client")

---@class Cursor
---@field line integer
---@field col integer

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

	vim.api.nvim_create_user_command("ConnectToServer", function()
		tcp.connect("127.0.0.1", 9999)
		-- vim.api.nvim_buf_get_lines(0, 0, -1, false)

		vim.api.nvim_create_autocmd("CursorMoved", {
			callback = tcp.send_cursor,
			group = vim.api.nvim_create_augroup("GoServerCursorSync", { clear = true }),
		})
	end, {})

	vim.api.nvim_create_user_command("StartConvimServer", function()
		vim.fn.jobstart({ "go", "run", "../server/main.go" }, {
			-- this is only for debug purposes
			on_stdout = function(_, data)
				if data then
					for _, line in ipairs(data) do
						if line ~= "" then
							print("[GoServer] " .. line)
						end
					end
				end
			end,
			on_stderr = function()
				vim.notify("[GoServer ERROR] " .. vim.log.levels.ERROR)
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
		print("Sending buffer ", payload)
		client:write(payload)
	end, {})
end

return M
