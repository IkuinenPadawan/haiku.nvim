local M = {}

M.notes_winnr = nil

M.setup = function(opts)
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

	local buf = vim.api.nvim_create_buf(false, true)

	local winnr = vim.api.nvim_open_win(buf, true, opts)

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
