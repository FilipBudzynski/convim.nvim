local M = {}
local Connection = require("client")
local ConvimGroup = require("autocmd")

M.start = function(opts)
	opts = opts or {}
	vim.api.nvim_create_user_command("StartConvimServer", function()
		local file_dir = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
		local server_dir = vim.fs.normalize(file_dir .. "../server")
		vim.system({ "go", "run", "." }, {
			cwd = server_dir,
			-- debug
			stdout = function(_, data)
				if data then
					print("[GoServer] " .. data)
				end
			end,
			-- debug
			stderr = function(_, data)
				if data then
					vim.schedule(function()
						vim.notify("[GoServer ERROR] " .. vim.log.levels.ERROR .. data)
					end)
				end
			end,
		})
	end, {})

	vim.api.nvim_create_user_command("StartSession", function()
		Connection.connect("127.0.0.1", 9999)

		-- send the whole buffer
		Connection.send_current_buffer()

		vim.api.nvim_create_autocmd({ "CursorMoved" }, {
			group = ConvimGroup,
			callback = Connection.send_cursor,
		})

		local _ = vim.api.nvim_buf_attach(0, false, {
			on_bytes = Connection.send_byte_change,
		})

		-- local success = vim.api.nvim_buf_attach(0, false, {
		-- 	-- on_bytes = Connection.send_change,
		-- 	on_bytes = function()
		-- 		print("buffer changed")
		-- 	end,
		-- })
		-- print(success)
	end, {})

	vim.api.nvim_create_user_command("ConnectToServer", function()
		Connection.connect("127.0.0.1", 9999)
		print("we are after the connection")

		vim.api.nvim_create_autocmd({ "CursorMoved" }, {
			group = ConvimGroup,
			callback = Connection.send_cursor,
		})

		local _ = vim.api.nvim_buf_attach(0, false, {
			on_bytes = Connection.send_byte_change,
		})

		-- local buf = vim.api.nvim_get_current_buf()
		-- local success = vim.api.nvim_buf_attach(buf, false, {
		-- 	-- on_bytes = Connection.send_change,
		-- 	on_bytes = function()
		-- 		print("buffer changed")
		-- 	end,
		-- })

		-- vim.api.nvim_create_autocmd({ "TextChangedI" }, {
		-- 	group = ConvimGroup,
		-- 	callback = Connection.send_char,
		-- })
	end, {})

	vim.api.nvim_create_user_command("Disconnect", function()
		Connection.disconnect()
	end, {})
end

return M
