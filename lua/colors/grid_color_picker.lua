local colors = require("colors.colors")
local utils = require("colors.colors_utils")

local M = {}

--- @class ColorHSL : Color
--- @field h number Hue value
--- @field s number Saturation value
--- @field l number Lightness value

-- =============================================================================
-- LOGIC & DATA PROCESSING
-- =============================================================================

--- Sorts colors by HSL for perceptual grouping
--- @param colors_ Color[] Array of color objects with name and color fields
--- @return ColorHSL[] Sorted array of color objects with HSL values added
local function get_sorted_color_data(colors_)
	local sorted = {}

	for _, c in ipairs(colors_) do
		local r, g, b = utils.int_to_rgb(c.color)
		local h, s, l = utils.rgb_to_hsl(r, g, b)
		table.insert(sorted, { color = c.color, name = c.name, h = h, s = s, l = l })
	end

	table.sort(sorted, function(a, b)
		if a.h ~= b.h then
			return a.h < b.h
		end
		if a.s ~= b.s then
			return a.s < b.s
		end
		return a.l < b.l
	end)

	return sorted
end

--- Calculates the optimal rows and columns for a given number of items
--- Uses a rectangular layout algorithm to minimize wasted space
--- @param n number Total number of color items to display
--- @return number rows Number of rows in the grid
--- @return number cols Number of columns in the grid
--- @return number total_slots Total grid slots (rows * cols)
local function calculate_grid_dimensions(n)
	local l = math.ceil(math.sqrt(n / 2))
	local rows = l
	local cols = 2 * l
	local total_slots = rows * cols

	-- Optimization to shrink the window if it's too large for the dataset
	if total_slots - (2 * l) > n then
		rows = rows - 1
		total_slots = total_slots - (2 * l)
	elseif total_slots - l > n then
		cols = cols - 1
		total_slots = total_slots - l
	end

	return rows, cols, total_slots
end

-- =============================================================================
-- BUFFER & HIGHLIGHTING
-- =============================================================================

--- Creates a grid of colored blocks representing the color palette
--- Populates the buffer with spaces and applies the background highlights
--- @param buf number Buffer handle to populate
--- @param grid ColorHSL[] Array of color data with HSL values
--- @param rows number Number of rows in the grid
--- @param cols number Number of columns in the grid
--- @return number Namespace ID used for the highlights
local function setup_buffer_content(buf, grid, rows, cols)
	local ns_id = vim.api.nvim_create_namespace("color_picker_grid")

	-- Create blank lines of spaces
	local lines = {}
	local line_str = string.rep("   ", cols)
	for _ = 1, rows do
		table.insert(lines, line_str)
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

	-- Apply background colors
	for r = 0, rows - 1 do
		for c = 0, cols - 1 do
			local idx = r * cols + c + 1
			local item = grid[idx]
			if item then
				local hex = utils.int_to_hex(item.color)
				local hl_group = "ColorPickerGrid_" .. idx
				vim.api.nvim_set_hl(0, hl_group, { bg = hex })
				local start_col = c * 3
				vim.hl.range(buf, ns_id, hl_group, { r, start_col }, { r, start_col + 3 })
			end
		end
	end

	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
	return ns_id
end

-- =============================================================================
-- INTERACTION & KEYMAPS
-- =============================================================================

local ns_cursor = vim.api.nvim_create_namespace("color_picker_cursor")

--- Highlights the current color cell and displays color name/hex in the command line
--- @param buf number Buffer handle
--- @param win number Window handle
--- @param grid ColorHSL[] Array of color data
--- @param dims table Dimensions table with rows, cols, total_slots
local function update_cursor_visuals(buf, win, grid, dims)
	local cursor = vim.api.nvim_win_get_cursor(win)
	local r, c = cursor[1] - 1, cursor[2]
	local idx = r * dims.cols + (c / 3) + 1
	local item = grid[idx]

	vim.api.nvim_buf_clear_namespace(buf, ns_cursor, 0, -1)

	if item and item.color then
		local bg_hex = utils.int_to_hex(item.color)
		local is_light = utils.relative_luminance(utils.int_to_rgb(item.color)) > 0.5
		local contrast_color = is_light and "#000000" or "#ffffff"

		vim.api.nvim_set_hl(0, "ColorPickerActive", {
			bg = bg_hex,
			fg = contrast_color,
			bold = true,
			sp = contrast_color,
			underline = true,
		})
		vim.hl.range(buf, ns_cursor, "ColorPickerActive", { r, c }, { r, c + 3 }, { priority = 200 })

		-- Echo color info
		local info = string.format("%s %s", item.name, bg_hex)
		vim.api.nvim_echo({ { info, "None" } }, false, {})
	end
end

--- Moves cursor in the specified direction, wrapping around grid edges
--- @param win number Window handle
--- @param dims table Dimensions table with rows, cols, total_slots
--- @param dr number Row delta (-1, 0, 1)
--- @param dc number Column delta (-1, 0, 1)
local function move_cursor(win, dims, dr, dc)
	local cursor = vim.api.nvim_win_get_cursor(win)
	local curr_r, curr_c = cursor[1] - 1, math.floor(cursor[2] / 3)
	local next_r = (curr_r + dr) % dims.rows
	local next_c = (curr_c + dc) % dims.cols
	vim.api.nvim_win_set_cursor(win, { next_r + 1, next_c * 3 })
end

--- Closes the color picker window and returns focus to original window/cursor position
--- @param win number Window handle of the picker to close
--- @param context table Context with original win and cursor position
local function close_picker(win, context)
	if vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	vim.api.nvim_set_current_win(context.win)
	vim.api.nvim_win_set_cursor(context.win, context.cursor)
end

--- Selects the current color and inserts its hex code into the original buffer
--- @param win number Window handle of the picker
--- @param grid ColorHSL[] Array of color data
--- @param dims table Dimensions table with rows, cols, total_slots
--- @param context table Context with original win and cursor position
local function select_color(win, grid, dims, context)
	local cursor = vim.api.nvim_win_get_cursor(win)
	local idx = (cursor[1] - 1) * dims.cols + (cursor[2] / 3) + 1

	if grid[idx] then
		local hex = utils.int_to_hex(grid[idx].color)
		close_picker(win, context)
		vim.api.nvim_put({ hex }, "c", true, true)
	end
end

--- Main entry point to bind all interactions for the color picker
--- Sets up autocommands, key mappings, and initial cursor visuals
--- @param buf number Buffer handle
--- @param win number Window handle
--- @param grid ColorHSL[] Array of color data
--- @param context table Context with original win and cursor position
--- @param dims table Dimensions table with rows, cols, total_slots
local function setup_interactions(buf, win, grid, context, dims)
	-- Setup Autocommands
	vim.api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		callback = function()
			local cursor = vim.api.nvim_win_get_cursor(win)
			-- Snap to grid if user clicks/moves manually to wrong column
			if cursor[2] % 3 ~= 0 then
				vim.api.nvim_win_set_cursor(win, { cursor[1], math.floor(cursor[2] / 3) * 3 })
				return
			end
			update_cursor_visuals(buf, win, grid, dims)
		end,
	})

	-- Setup Keymaps
	local map_opts = { buffer = buf, noremap = true, silent = true }
	local moves = {
		h = { 0, -1 },
		l = { 0, 1 },
		k = { -1, 0 },
		j = { 1, 0 },
		["<Left>"] = { 0, -1 },
		["<Right>"] = { 0, 1 },
		["<Up>"] = { -1, 0 },
		["<Down>"] = { 1, 0 },
	}

	for key, dir in pairs(moves) do
		vim.keymap.set("n", key, function()
			move_cursor(win, dims, dir[1], dir[2])
		end, map_opts)
	end

	vim.keymap.set("n", "<Esc>", function()
		close_picker(win, context)
	end, map_opts)
	vim.keymap.set("n", "q", function()
		close_picker(win, context)
	end, map_opts)
	vim.keymap.set("n", "<CR>", function()
		select_color(win, grid, dims, context)
	end, map_opts)

	-- Initial Render
	update_cursor_visuals(buf, win, grid, dims)
end

-- =============================================================================
-- MAIN ENTRY POINT
-- =============================================================================

--- Opens an interactive 2D color picker
--- Displays colors in a grid layout sorted by HSL values
--- @return nil
function M.pick_color()
	-- Store context
	local context = {
		win = vim.api.nvim_get_current_win(),
		cursor = vim.api.nvim_win_get_cursor(0),
	}

	-- Prep Data
	local color_data = get_sorted_color_data(colors)
	local rows, cols, total_slots = calculate_grid_dimensions(#colors)

	-- Fill Grid (Ensuring table structure matches ColorHSL)
	local grid = {}
	for i = 1, total_slots do
		grid[i] = color_data[i] or { name = "black", color = 0x000000, h = 0, s = 0, l = 0 }
	end

	-- Create UI
	local buf = vim.api.nvim_create_buf(false, true)
	setup_buffer_content(buf, grid, rows, cols)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = cols * 3,
		height = rows,
		col = math.floor((vim.o.columns - (cols * 3)) / 2),
		row = math.floor((vim.o.lines - rows) / 2),
		style = "minimal",
		border = "rounded",
	})

	-- Save global guicursor
	local old_guicursor = vim.opt.guicursor:get()

	-- Set cursor to very thin vertical bar
	vim.opt.guicursor:append("a:ver1")

	-- Restore cursor when leaving the picker
	vim.api.nvim_create_autocmd("WinLeave", {
		buffer = buf,
		once = true,
		callback = function()
			vim.opt.guicursor = old_guicursor
		end,
	})

	-- Start interactions
	setup_interactions(buf, win, grid, context, { rows = rows, cols = cols, total_slots = total_slots })
end

vim.api.nvim_create_user_command("ColorPick2D", M.pick_color, {})

return M
