local M = {}

M.haikus_winnr = nil
M.haikus_panel = nil
M.saved_context = {}

M.setup = function(opts)
  opts = opts or {}

  M.haikus_path = opts.haikus_path or vim.fn.expand '~/.local/share/nvim/haiku/haikus.md'
  M.create_haikus_file()

  M.daily_headers = opts.daily_headers or true

  M.keymaps = vim.tbl_deep_extend('force', {
    toggle_add_haiku = '<Leader>h',
    toggle_haikus = '<Leader>H',
  }, opts.keymaps or {})

  vim.api.nvim_create_user_command('Haiku', function()
    M.toggle_add_haiku()
  end, {})

  vim.api.nvim_set_keymap(
    'n',
    M.keymaps.toggle_add_haiku,
    ':lua require("haiku").toggle_add_haiku()<CR>',
    { noremap = true, silent = true }
  )

  vim.api.nvim_set_keymap(
    'n',
    M.keymaps.toggle_haikus,
    ':lua require("haiku").toggle_haikus()<CR>',
    { noremap = true, silent = true }
  )
end

M.get_date_header = function()
  local todays_date = os.date '%d-%m-%Y'
  return '## ' .. todays_date
end

M.create_haikus_file = function()
  if vim.fn.filereadable(M.haikus_path) ~= 1 then
    local dir_path = vim.fn.fnamemodify(M.haikus_path, ':h')
    vim.fn.mkdir(dir_path, 'p')
    local file = io.open(M.haikus_path, 'w')
    if file then
      file:write '# Haikus\n\n'
      file:close()
    end
  end
end

M.find_header_line = function(lines, header)
  for i = #lines, 1, -1 do
    local line = lines[i]
    if line == header then
      return i
    end
  end
  return nil
end

M.get_insertion_point = function(lines, header_line)
  if header_line == nil then
    return 1
  end

  return header_line + 1
end

M.get_context = function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == M.haikus_path or vim.bo.buftype == 'terminal' then
    return nil
  end

  return { vim.api.nvim_buf_get_name(0), vim.fn.line '.' }
end

M.setup_buffer_options = function(bufnr)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(bufnr, 'modified', false)

  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = bufnr,
    callback = function()
      if M.haikus_winnr then
        M.haikus_winnr = nil
      end
    end,
  })

  vim.api.nvim_create_autocmd('QuitPre', {
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
      if line:match '%S' then
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

        for _, line in ipairs(lines) do
          table.insert(new_content, line)
        end

        if not M.daily_headers then
          vim.api.nvim_buf_set_lines(haikus_bufnr, 1, 1, false, new_content)
        else
          local today_header = M.get_date_header()
          local header_idx = M.find_header_line(current_lines, today_header)
          local insertion_point = M.get_insertion_point(current_lines, header_idx)

          if header_idx == nil then
            table.insert(new_content, 1, today_header)
          end

          if M.saved_context ~= nil then
            table.insert(new_content, '`→ ' .. M.saved_context[1] .. ':' .. M.saved_context[2] .. '`')
          end

          table.insert(new_content, '')

          vim.api.nvim_buf_set_lines(haikus_bufnr, insertion_point - 1, insertion_point - 1, false, new_content)
        end

        vim.api.nvim_buf_call(haikus_bufnr, function()
          vim.cmd 'silent write'
        end)

        vim.notify('Haiku saved', vim.log.levels.INFO)
      end
    end
    vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    vim.api.nvim_win_close(M.haikus_winnr, true)
    M.haikus_winnr = nil
  end
end

M.discard_and_close = function()
  if M.haikus_winnr and vim.api.nvim_win_is_valid(M.haikus_winnr) then
    local bufnr = vim.api.nvim_win_get_buf(M.haikus_winnr)
    vim.api.nvim_buf_set_option(bufnr, 'modified', false)
    vim.api.nvim_win_close(M.haikus_winnr, true)
    M.haikus_winnr = nil
    vim.notify('Note discarded', vim.log.levels.INFO, { title = 'Haiku' })
  end
end

M.create_floating_window = function()
  local width = math.floor(vim.o.columns * 0.3)
  local height = 3

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = 'Haiku',
    title_pos = 'center',
  }

  local buffer = vim.api.nvim_create_buf(false, true)
  M.setup_buffer_options(buffer)
  vim.api.nvim_buf_set_keymap(
    buffer,
    'n',
    '<CR>',
    '<cmd>lua require("haiku").save_and_close()<CR>',
    { noremap = true, desc = 'Save note and close window' }
  )

  vim.api.nvim_buf_set_keymap(
    buffer,
    'n',
    '<Esc>',
    '<cmd>lua require("haiku").save_and_close()<CR>',
    { noremap = true, silent = true, desc = 'Save note and close' }
  )

  vim.api.nvim_buf_set_keymap(
    buffer,
    'i',
    '<C-c>',
    '<cmd>lua require("haiku").discard_and_close()<CR>',
    { noremap = true, silent = true, desc = 'Discard note and close' }
  )

  local winnr = vim.api.nvim_open_win(buffer, true, opts)
  vim.cmd 'startinsert'
  vim.api.nvim_win_set_option(winnr, 'winblend', 10)
  vim.api.nvim_win_set_option(winnr, 'cursorline', true)

  return winnr
end

M.get_haikus_buffer = function()
  local haikus_bufnr = vim.fn.bufnr(M.haikus_path)
  if haikus_bufnr == -1 then
    haikus_bufnr = vim.fn.bufadd(M.haikus_path)
    vim.fn.bufload(haikus_bufnr)
  end

  return haikus_bufnr
end

M.create_floating_panel = function()
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local width = math.floor(win_width / 3)
  local col = win_width - width
  local row = 0

  local opts = {
    relative = 'win',
    win = 0,
    width = width,
    height = win_height,
    col = col,
    row = row,
    anchor = 'NW',
    style = 'minimal',
  }

  local bufnr = M.get_haikus_buffer()

  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'markdown')
  vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(bufnr, 'buftype', '')
  vim.api.nvim_buf_set_option(bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(bufnr, 'modified', false)

  local winnr = vim.api.nvim_open_win(bufnr, true, opts)

  vim.api.nvim_win_set_option(winnr, 'winhl', 'Normal:PanelNormal')

  return winnr
end

M.toggle_add_haiku = function()
  if M.haikus_winnr and vim.api.nvim_win_is_valid(M.haikus_winnr) then
    vim.api.nvim_win_close(M.haikus_winnr, true)
    M.haikus_winnr = nil
  else
    M.saved_context = M.get_context()
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

return M
