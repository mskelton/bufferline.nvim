local api = _G.vim.api
local highlight = '%#BufferLine#'
local selected_highlight = '%#BufferLineSelected#'
local background = '%#BufferLineBackground#%T'
local close = '%=%#BufferLine#%999X'
local padding = " "

local function safely_get_var(var)
  if pcall(function() api.nvim_get_var(var) end) then
    return api.nvim_get_var(var)
  else
    return nil
  end
end

-- Source: https://teukka.tech/luanvim.html
local function nvim_create_augroups(definitions)
  for group_name, definition in pairs(definitions) do
    api.nvim_command('augroup '..group_name)
    api.nvim_command('autocmd!')
    for _,def in pairs(definition) do
      local command = table.concat(_G.vim.tbl_flatten{'autocmd', def}, ' ')
      api.nvim_command(command)
    end
    api.nvim_command('augroup END')
  end
end

local function get_hex(hl_name, part)
  local id = api.nvim_call_function('hlID', {hl_name})
  return api.nvim_call_function('synIDattr', {id, part})
end

-- This is a global so it can be called from our autocommands
function _G.colors()
  -- local default_colors = {
  --   gold         = '#F5F478',
  --   bright_blue  = '#A2E8F6',
  --   dark_blue    = '#4e88ff',
  --   dark_yellow  = '#d19a66',
  --   green        = '#98c379'
  -- }

  local comment_fg = get_hex('Comment', 'fg')
  local normal_bg= get_hex('Normal', 'bg')
  local normal_fg= get_hex('Normal', 'fg')

  -- TODO: fix hard coded colors
  api.nvim_command("highlight! TabLineFill guibg=#1b1e24")
  api.nvim_command("highlight! BufferLineBackground guibg=#1b1e24")
  api.nvim_command("highlight! BufferLine guifg="..comment_fg..' guibg=#1b1e24 gui=NONE')
  api.nvim_command('highlight! BufferLineSelected guifg='..normal_fg..' guibg='..normal_bg..' gui=bold,italic')

end

local function make_clickable(item, buf_num)
  local is_clickable = api.nvim_call_function('has', {'tablineat'})
  if is_clickable then
    return "%"..buf_num.."@HandleBufferlineClick@"..item
  else
    return item
  end
end

local function add_buffer(line, path, buf_num)
  if path == "" then
    path = "[No Name]"
  elseif string.find(path, 'term://') ~= nil then
    return ' '..api.nvim_call_function('fnamemodify', {path, ":p:t"})..padding
  end

  local modified = api.nvim_buf_get_option(buf_num, 'modified')
  local file_name = api.nvim_call_function('fnamemodify', {path, ":p:t"})
  local is_current = api.nvim_get_current_buf() == buf_num
  local buf_highlight = is_current and selected_highlight or highlight
  local devicons_loaded = api.nvim_call_function('exists', {'*WebDevIconsGetFileTypeSymbol'})
  line = line..buf_highlight

  -- parameters: a:1 (filename), a:2 (isDirectory)
  local icon = devicons_loaded and api.nvim_call_function('WebDevIconsGetFileTypeSymbol', {path}) or ""
  local buffer = padding..icon..padding..file_name..padding
  local clickable_buffer = make_clickable(buffer, buf_num)
  line = padding..line..clickable_buffer

  if modified then
    local modified_icon = safely_get_var("bufferline_modified_icon")
    modified_icon = modified_icon ~= nil and modified_icon or "●"
    line = line..modified_icon..padding
  end

  return line
end

-- The provided api nvim_is_buf_loaded filters out all hidden buffers
local function is_valid(buffer)
  local listed = api.nvim_buf_get_option(buffer, "buflisted")
  local exists = api.nvim_buf_is_valid(buffer)
  return listed and exists
end

-- TODO
-- Show tabs
-- Handle keeping active buffer always in view
-- Truncation
local function bufferline()
  local buf_nums = api.nvim_list_bufs()
  local line = ""
  for _,v in pairs(buf_nums) do
    if is_valid(v) then
      local name =  api.nvim_buf_get_name(v)
      line = add_buffer(line, name, v)
    end
  end
  local icon = safely_get_var("bufferline_close_icon")
  icon = icon ~= nil and icon or "close "
  line = line..background
  line = line..padding..close..icon
  return line
end

local function setup()
  nvim_create_augroups({
      BufferlineColors = {
        {"VimEnter", "*", [[lua colors()]]};
        {"ColorScheme", "*", [[lua colors()]]};
      }
    })
end

return {
  setup = setup,
  bufferline = bufferline
}

