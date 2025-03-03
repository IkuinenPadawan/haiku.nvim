local M = {}

M.notes_winnr = nil

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
	}

	local buffer = vim.api.nvim_create_buf(false, true)
	M.setup_buffer_options(buffer)

	local winnr = vim.api.nvim_open_win(buffer, true, opts)

	vim.api.nvim_win_set_option(winnr, "winblend", 10)
	vim.api.nvim_win_set_option(winnr, "cursorline", true)

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

M.setup()

return M
