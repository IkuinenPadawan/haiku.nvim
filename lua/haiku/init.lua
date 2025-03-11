local M = {}

M.haikus_winnr = nil
M.haikus_panel = nil

M.setup = function(opts)
	opts = opts or {}

	M.haikus_path = opts.haikus_path or vim.fn.expand("~/.local/share/nvim/haiku/haikus.md")
	M.create_haikus_file()

	M.keymaps = vim.tbl_deep_extend("force", {
		toggle_add_haiku = "<Leader>h",
		toggle_haikus = "<Leader>H",
	}, opts.keymaps or {})

	vim.api.nvim_create_user_command("Haiku", function()
		M.toggle_add_haiku()
	end, {})

	vim.api.nvim_set_keymap(
		"n",
		M.keymaps.toggle_add_haiku,
		':lua require("haiku").toggle_add_haiku()<CR>',
		{ noremap = true, silent = true }
	)

	vim.api.nvim_set_keymap(
		"n",
		M.keymaps.toggle_haikus,
		':lua require("haiku").toggle_haikus()<CR>',
		{ noremap = true, silent = true }
	)
end

M.create_haikus_file = function()
	if vim.fn.filereadable(M.haikus_path) ~= 1 then
		local dir_path = vim.fn.fnamemodify(M.haikus_path, ":h")
		vim.fn.mkdir(dir_path, "p")
		local file = io.open(M.haikus_path, "w")
		if file then
			file:write("# Haikus\n\n")
			file:close()
		end
	end
end

M.setup_buffer_options = function(bufnr)
	vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
	vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(bufnr, "modified", false)

	vim.api.nvim_create_autocmd("BufWinLeave", {
		buffer = bufnr,
		callback = function()
			if M.haikus_winnr then
				M.haikus_winnr = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd("QuitPre", {
		buffer = bufnr,
		callback = function()
			M.save_and_close()
			return true
		end,
	})
end

M.save_and_close = function()
	if M.haikus_winnr and vim.api.nvim_win_is_valid(M.haikus_winnr) then
		local bufnr = vim.api.nvim_win_get_buf(M.haikus_winnr)
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

		local has_content = false
		for _, line in ipairs(lines) do
			if line:match("%S") then
				has_content = true
				break
			end
		end

		if has_content then
			if #lines > 0 then
				local haikus_bufnr = vim.fn.bufnr(M.haikus_path)
				if haikus_bufnr == -1 then
					haikus_bufnr = vim.fn.bufadd(M.haikus_path)
					vim.fn.bufload(haikus_bufnr)
				end

				local current_lines = vim.api.nvim_buf_get_lines(haikus_bufnr, 0, -1, false)

				local new_content = {}
				table.insert(new_content, "")

				for _, line in ipairs(lines) do
					table.insert(new_content, line)
				end

				vim.api.nvim_buf_set_lines(haikus_bufnr, #current_lines, #current_lines, false, new_content)

				vim.api.nvim_buf_call(haikus_bufnr, function()
					vim.cmd("silent write")
				end)

				vim.notify("Haiku saved", vim.log.levels.INFO)
			end
		end
		vim.api.nvim_buf_set_option(bufnr, "modified", false)
		vim.api.nvim_win_close(M.haikus_winnr, true)
		M.haikus_winnr = nil
	end
end

M.discard_and_close = function()
	if M.haikus_winnr and vim.api.nvim_win_is_valid(M.haikus_winnr) then
		local bufnr = vim.api.nvim_win_get_buf(M.haikus_winnr)
		vim.api.nvim_buf_set_option(bufnr, "modified", false)
		vim.api.nvim_win_close(M.haikus_winnr, true)
		M.haikus_winnr = nil
		vim.notify("Note discarded", vim.log.levels.INFO, { title = "Haiku" })
	end
end

M.create_floating_window = function()
	local width = math.floor(vim.o.columns * 0.3)
	local height = math.floor(vim.o.lines * 0.1)

	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = "Haiku",
		title_pos = "center",
	}

	local buffer = vim.api.nvim_create_buf(false, true)
	M.setup_buffer_options(buffer)
	vim.api.nvim_buf_set_keymap(
		buffer,
		"n",
		"<CR>",
		'<cmd>lua require("haiku").save_and_close()<CR>',
		{ noremap = true, desc = "Save note and close window" }
	)

	vim.api.nvim_buf_set_keymap(
		buffer,
		"n",
		"<Esc>",
		'<cmd>lua require("haiku").save_and_close()<CR>',
		{ noremap = true, silent = true, desc = "Save note and close" }
	)

	vim.api.nvim_buf_set_keymap(
		buffer,
		"i",
		"<C-c>",
		'<cmd>lua require("haiku").discard_and_close()<CR>',
		{ noremap = true, silent = true, desc = "Discard note and close" }
	)

	local winnr = vim.api.nvim_open_win(buffer, true, opts)
	vim.cmd("startinsert")
	vim.api.nvim_win_set_option(winnr, "winblend", 10)
	vim.api.nvim_win_set_option(winnr, "cursorline", true)

	return winnr
end

M.get_haikus_buffer = function()
	local buf = vim.api.nvim_create_buf(true, false)
	local file = io.open(M.haikus_path, "r")
	if not file then
		vim.api.nvim_err_writeln("Failed to open file: " .. M.haikus_path)
		return
	end

	local lines = {}
	for line in file:lines() do
		table.insert(lines, line)
	end

	file:close()

	return { buf = buf, lines = lines }
end

M.create_floating_panel = function()
	local win_width = vim.api.nvim_win_get_width(0)
	local win_height = vim.api.nvim_win_get_height(0)
	local width = math.floor(win_width / 3)
	local col = win_width - width
	local row = 0

	local opts = {
		relative = "win",
		win = 0,
		width = width,
		height = win_height,
		col = col,
		row = row,
		anchor = "NW",
		style = "minimal",
	}

	local buffer = M.get_haikus_buffer()

	vim.api.nvim_buf_set_option(buffer.buf, "filetype", "markdown")
	vim.api.nvim_buf_set_option(buffer.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buffer.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buffer.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buffer.buf, "modified", false)

	vim.api.nvim_buf_set_lines(buffer.buf, 0, -1, false, buffer.lines)

	vim.api.nvim_buf_set_option(buffer.buf, "modifiable", false)

	local winnr = vim.api.nvim_open_win(buffer.buf, true, opts)

	vim.api.nvim_win_set_option(winnr, "winhl", "Normal:PanelNormal")

	return winnr
end

M.toggle_add_haiku = function()
	if M.haikus_winnr and vim.api.nvim_win_is_valid(M.haikus_winnr) then
		vim.api.nvim_win_close(M.haikus_winnr, true)
		M.haikus_winnr = nil
	else
		M.haikus_winnr = M.create_floating_window()
	end
end

M.toggle_haikus = function()
	if M.haikus_panel and vim.api.nvim_win_is_valid(M.haikus_panel) then
		vim.api.nvim_win_close(M.haikus_panel, true)
		M.haikus_panel = nil
	else
		M.haikus_panel = M.create_floating_panel()
	end
end

M.setup()

return M
