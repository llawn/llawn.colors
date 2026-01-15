--- @brief Simple color highlighter for Neovim
--- Highlights hex colors with their own background color and inline hints

local MAX_LINES = 5000  -- Constant for maximum lines to process
local ENABLED = true

local colors = require('llawn.colors.colors')
local colors_utils = require('llawn.colors.colors_utils')

local ns_highlight = vim.api.nvim_create_namespace('color_highlights')
local ns_virtual = vim.api.nvim_create_namespace('color_virtual')


--- finds the best matching color from the list in ./colors.lua
--- @param color_int integer: The color as an integer (e.g., 0xff0000)
--- @return Color|nil best_match: The best matching color
local function find_best_match(color_int)
  local best_match = nil
  local min_dist = math.huge
  for _, color in ipairs(colors) do
    local dist = colors_utils.color_distance(color_int, color.color)
    if dist < min_dist then
      min_dist = dist
      best_match = color
    end
  end
  return best_match
end

--- Sets up a highlight group with the specified foreground and background colors.
---
--- @param bufnr integer: The buffer number where the highlight will be applied.
--- @param _ns_highlight integer: The namespace for the highlight.
--- @param line_idx integer: The line index where the highlight should start.
--- @param start_col integer: The starting column for the highlight.
--- @param end_col integer: The ending column for the highlight.
--- @param color_int integer: The color as an integer (e.g., 0xff0000).
local function set_highlight(bufnr, _ns_highlight, line_idx, start_col, end_col, color_int)
  local hl_group = string.format("Color_%06x", color_int)

  local r, g, b = colors_utils.int_to_rgb(color_int)
  local luminance = colors_utils.relative_luminance(r, g, b)
  local fg = luminance > 0.5 and "#000000" or "#ffffff"

  -- Set up the highlight group with specified foreground and background colors
  vim.cmd(string.format("highlight %s guibg=#%06x guifg=%s", hl_group, color_int, fg))

  -- Apply the highlight group at the specified location
  vim.api.nvim_buf_set_extmark(
    bufnr,
    _ns_highlight,
    line_idx,
    start_col,
    { end_col = end_col, hl_group = hl_group }
  )
end

--- Sets a hint in the specified buffer as virtual text based of the color_int value
--- find the best matching colors in the list of colors in ./colors.lua
--- and display a hint accordingly.
---
--- @param bufnr integer: The buffer number where the hint will be displayed.
--- @param _ns_virtual integer: The namespace for the virtual text.
--- @param line_idx integer: The line index where the hint should appear.
--- @param start_col integer: The starting column for the hint.
--- @param color_int integer: The color as an integer (e.g., 0xff0000).
local function set_hint(bufnr, _ns_virtual, line_idx, start_col, color_int)
  local best_match = find_best_match(color_int)

  if best_match then
    local match_hex = colors_utils.int_to_hex(best_match.color)
    local percent = colors_utils.color_similarity(color_int, best_match.color)
    local hint

    if percent >= 1 then
      hint = "[" .. best_match.name .. "] "
    else
      hint = string.format("[%s %s %.1f%%] ", best_match.name, match_hex, percent * 100)
    end

    -- Set virtual text hint
    vim.api.nvim_buf_set_extmark(
      bufnr,
      _ns_virtual,
      line_idx,
      start_col,
      { virt_text = {{hint, "Comment"}}, virt_text_pos = "inline" }
    )
  end
end

--- Highlights and sets a hint for a specified range of text in a buffer based of the color_int value
--- @param bufnr integer: The buffer number where the highlights and hints will be displayed.
--- @param _ns_highlight integer: The namespace for the highlight.
--- @param _ns_virtual integer: The namespace for the virtual text.
--- @param line_idx integer: The line index where the highlight and hint should appear.
--- @param start_col integer: The starting column for the highlight and hint.
--- @param color_int integer: The color as an integer (e.g., 0xff0000).
local function highlight_and_hint(bufnr, _ns_highlight, _ns_virtual, line_idx, start_col, end_col, color_int)
  set_highlight(bufnr, _ns_highlight, line_idx, start_col, end_col, color_int)
  set_hint(bufnr, _ns_virtual, line_idx, start_col, color_int)
end

--- Helper to scan a line for a specific pattern and apply highlights and hints
--- @param bufnr integer: The buffer number where the highlights and hints will be displayed.
--- @param line string: The line to scans for highlights and hints
--- @param line_idx integer: The line index where the highlight and hint should appear.
--- @param pattern string: The pattern to scan
--- @param prefix_len integer: The prefix length (Prefix length 1 for '#' and 2 for '0x')
local function scan_and_highlight(bufnr, line, line_idx, pattern, prefix_len)
  local init = 1
  while true do
    local s, e = line:find(pattern, init)
    if not s then break end

    local hex_digits = line:sub(s + prefix_len, e)
    local next_char = line:sub(e + 1, e + 1)

    -- Validation
    local valid_length = #hex_digits >= 1 and #hex_digits <= 6
    local is_not_hex = next_char == "" or not next_char:match("%x")
    local is_not_word = next_char == "" or not next_char:match("[_G-Zg-z]")

    if valid_length and is_not_hex and is_not_word then
      local hex_code = "#" .. hex_digits
      local c = colors_utils.hex_to_int(hex_code)
      if c then
        highlight_and_hint(bufnr, ns_highlight, ns_virtual, line_idx, s - 1, e, c)
      end
    end
    init = e + 1
  end
end

--- Highlights color codes in the specified buffer.
---
--- This function scans the lines of a given buffer for color codes in hex format 
--- If the buffer exceeds MAX_LINES lines, only the first MAX_LINES lines will be processed 
--- to prevent performance issues.
---
--- @param bufnr integer|nil: The buffer number where the highlights and hints will be displayed (defaults to 0).
local function highlight_colors(bufnr)
  if not ENABLED then return end
  bufnr = bufnr or 0

  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns_highlight, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_virtual, 0, -1)

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(line_count, MAX_LINES), false)

  for i, line in ipairs(lines) do
    local line_idx = i - 1
    scan_and_highlight(bufnr, line, line_idx, "#%x+", 1)
    scan_and_highlight(bufnr, line, line_idx, "0x%x+", 2)
  end
end

local M = {}

-- Toggle highlight_colors and hints 
function M.toggle()
  if ENABLED then
    ENABLED = false
    vim.api.nvim_buf_clear_namespace(0, ns_highlight, 0, -1)
    vim.api.nvim_buf_clear_namespace(0, ns_virtual, 0, -1)
  else
    ENABLED = true
    highlight_colors(0)
  end
end

function M.setup()
  vim.keymap.set('n', '<leader>ct', M.toggle, { silent = true, desc = "Toggle color highlights" })
  vim.api.nvim_create_autocmd({'BufEnter', 'BufRead'}, {
    pattern = '*',
    callback = function(args)
      highlight_colors(args.buf)
    end
  })

  vim.api.nvim_create_autocmd({'TextChanged', 'TextChangedI'}, {
    pattern = '*',
    callback = function(args)
      highlight_colors(args.buf)
    end
  })

  -- Highlight current buffer
  if vim.fn.expand('%') ~= '' then
    highlight_colors()
  end
end

return M

