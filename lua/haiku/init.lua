local M = {}

M.notes_winnr = nil
M.notes_panel = nil

M.setup = function(opts)
	M.create_notes_file()
	vim.api.nvim_create_user_command("Haiku", function()
		M.toggle_notes()
	end, {})
	vim.api.nvim_set_keymap(
		"n",
		"<Leader>h",
		':lua require("haiku").toggle_notes()<CR>',
		{ noremap = true, silent = true }
	)

	vim.api.nvim_set_keymap(
		"n",
		"<Leader>j",
		':lua require("haiku").toggle_panel()<CR>',
		{ noremap = true, silent = true }
	)
end

M.notes_path = vim.fn.expand("~/.local/share/nvim/haiku/notes.md")

M.create_notes_file = function()
	if vim.fn.filereadable(M.notes_path) ~= 1 then
		local dir_path = vim.fn.fnamemodify(M.notes_path, ":h")
		vim.fn.mkdir(dir_path, "p")
		local file = io.open(M.notes_path, "w")
		if file then
			file:write("# Haiku notes\n\n")
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
			if M.notes_winnr then
				M.notes_winnr = nil
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
	if M.notes_winnr and vim.api.nvim_win_is_valid(M.notes_winnr) then
		local bufnr = vim.api.nvim_win_get_buf(M.notes_winnr)
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
				local notes_bufnr = vim.fn.bufnr(M.notes_path)
				if notes_bufnr == -1 then
					notes_bufnr = vim.fn.bufadd(M.notes_path)
					vim.fn.bufload(notes_bufnr)
				end

				local current_lines = vim.api.nvim_buf_get_lines(notes_bufnr, 0, -1, false)

				local new_content = {}
				table.insert(new_content, "")

				for _, line in ipairs(lines) do
					table.insert(new_content, line)
				end

				vim.api.nvim_buf_set_lines(notes_bufnr, #current_lines, #current_lines, false, new_content)

				vim.api.nvim_buf_call(notes_bufnr, function()
					vim.cmd("silent write")
				end)

				vim.notify("Haiku saved", vim.log.levels.INFO)
			end
		end
		vim.api.nvim_buf_set_option(bufnr, "modified", false)
		vim.api.nvim_win_close(M.notes_winnr, true)
		M.notes_winnr = nil
	end
end

M.discard_and_close = function()
	if M.notes_winnr and vim.api.nvim_win_is_valid(M.notes_winnr) then
		local bufnr = vim.api.nvim_win_get_buf(M.notes_winnr)
		vim.api.nvim_buf_set_option(bufnr, "modified", false)
		vim.api.nvim_win_close(M.notes_winnr, true)
		M.notes_winnr = nil
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

M.get_notes_buffer = function()
	local buf = vim.api.nvim_create_buf(true, false)
	local file = io.open(M.notes_path, "r")
	if not file then
		vim.api.nvim_err_writeln("Failed to open file: " .. M.notes_path)
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

	local buffer = M.get_notes_buffer()

	vim.api.nvim_buf_set_lines(buffer.buf, 0, -1, false, buffer.lines)

	local winnr = vim.api.nvim_open_win(buffer.buf, true, opts)

	vim.api.nvim_win_set_option(winnr, "winhl", "Normal:PanelNormal")

	return winnr
end

M.toggle_notes = function()
	if M.notes_winnr and vim.api.nvim_win_is_valid(M.notes_winnr) then
		vim.api.nvim_win_close(M.notes_winnr, true)
		M.notes_winnr = nil
	else
		M.notes_winnr = M.create_floating_window()
	end
end

M.toggle_panel = function()
	if M.notes_panel and vim.api.nvim_win_is_valid(M.notes_panel) then
		vim.api.nvim_win_close(M.notes_panel, true)
		M.notes_panel = nil
	else
		M.notes_panel = M.create_floating_panel()
	end
end

M.setup()

return M
