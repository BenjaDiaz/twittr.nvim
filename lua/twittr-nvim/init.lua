--local pathOfThisFile = ...
--local folderOfThisFile = (...):match("(.-)[^%.]+$")
--package.path = './lua/twittr-nvim/?.lua;' .. package.path
--local json = require(folderOfThisFile .. 'json')
--local oauth = require(folderOfThisFile .. 'oauth')

local buf, win, preview_buf, preview_win, position, timeline_table

local function center(str)
  local width = vim.api.nvim_win_get_width(0)
  local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
  return string.rep(' ', shift) .. str
end

local function open_window()
  buf = vim.api.nvim_create_buf(false, true)
  preview_buf = vim.api.nvim_create_buf(false, true)
  local border_buf = vim.api.nvim_create_buf(false, true)

  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'filetype', 'twittr-nvim')

  vim.api.nvim_buf_set_option(preview_buf, 'filetype', 'twittr-nvim')

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines")

  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1
  }

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = math.ceil(win_height / 2),
    row = row,
    col = col
  }

  local preview_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = math.ceil(win_height / 2) - 2,
    row = row + math.ceil(win_height / 2) + 1,
    col = col
  }

  local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
  local middle_line = '║' .. string.rep(' ', win_width) .. '║'
  for i=1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')
  vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

  preview_win = vim.api.nvim_open_win(preview_buf, true, preview_opts)
  local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
  win = vim.api.nvim_open_win(buf, true, opts)
  vim.api.nvim_win_set_option(win, 'winhl', 'Normal:Twittr')
  vim.api.nvim_win_set_var(0, 'wrap', 0)
  vim.api.nvim_win_set_option(preview_win, 'winhl', 'Normal:Twittr')
  vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
  vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..preview_buf)

  vim.api.nvim_win_set_option(win, 'cursorline', true) -- it highlight line with the cursor on it

  -- we can add title already here, because first line will never change
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { center('Twitter Timeline'), '', ''})
  vim.api.nvim_buf_add_highlight(buf, -1, 'TwittrHeader', 0, 0, -1)

end


local function update_view()
  local list = {}

  local handle = io.popen("twurl '/1.1/statuses/home_timeline.json'")
  local timeline_response = handle:read("*a")
  handle:close()
  timeline_table = vim.fn.json_decode(timeline_response)

  for k, v in pairs(timeline_table) do
    table.insert(list, #list + 1, " @" .. v.user.screen_name .. " - " .. string.gsub(v.text, "\n", " "))
  end

  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(buf, 2, -1, false, list)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function update_preview()
  position = vim.api.nvim_win_get_cursor(win)[1] - 2
  if position < 0 then
    position = 0
  end
  if type(timeline_table) == "table" and #timeline_table > position and timeline_table[position] ~= nil then
    local preview_list = {
      timeline_table[position].created_at,
      "@" .. timeline_table[position].user.screen_name,
      "",
      "" .. string.gsub(timeline_table[position].text, "\n", " ")
    }
    vim.api.nvim_buf_set_option(preview_buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(preview_buf, 2, -1, false, preview_list)
    vim.api.nvim_buf_set_option(preview_buf, 'modifiable', false)
  end
end

local function open_timeline()
  position = 0
  open_window()
  update_view()
  update_preview()
  vim.api.nvim_win_set_cursor(win, {3, 0})
end

return {
  open_timeline = open_timeline,
  update_preview = update_preview
}
