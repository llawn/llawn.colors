--- Neovim commands for palette generation

local palette_gen = require("colors.palette_generator")
local palette_mgr = require("colors.palette_manager")

local M = {}

--- Generate and display a palette in a floating window
--- @param base_color string Base color name
--- @param method string Generation method
--- @param options table Optional generation parameters
function M.show_palette(base_color, method, options)
	local palette = palette_gen.generate_palette(base_color, method, options)

	if not palette then
		vim.notify("Base color '" .. base_color .. "' not found", vim.log.levels.ERROR)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {
		"Generated Palette: " .. method .. " from " .. base_color,
		string.rep("=", 50),
		"",
	}

	for i, color in ipairs(palette) do
		local hex = string.format("#%06X", color)
		table.insert(lines, string.format("%d. %s", i, hex))
	end

	table.insert(lines, "")
	table.insert(lines, "Press 's' to save this palette, 'q' to close")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local width = 50
	local height = #lines
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	}

	vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"s",
		':lua require("colors.palette_commands").save_current_palette()<CR>',
		{ noremap = true, silent = true }
	)

	vim.api.nvim_buf_set_var(buf, "palette_data", {
		palette = palette,
		method = method,
		base_color = base_color,
		options = options,
	})
end

--- Save the current palette shown in the floating window
function M.save_current_palette()
	local buf = vim.api.nvim_get_current_buf()
	local ok, data = pcall(vim.api.nvim_buf_get_var, buf, "palette_data")

	if not ok then
		vim.notify("No palette data found", vim.log.levels.ERROR)
		return
	end

	vim.ui.input({ prompt = "Palette name: " }, function(name)
		if not name or name == "" then
			vim.notify("Save cancelled", vim.log.levels.INFO)
			return
		end

		local success, err = palette_mgr.save_palette(data.palette, name, data.method, data.base_color, data.options)

		if success then
			vim.notify("Palette '" .. name .. "' saved successfully", vim.log.levels.INFO)
		else
			vim.notify("Failed to save palette: " .. (err or "unknown error"), vim.log.levels.ERROR)
		end

		vim.cmd("close")
	end)
end

--- List saved palettes
function M.list_palettes()
	local names = palette_mgr.get_saved_palette_names()

	if #names == 0 then
		vim.notify("No saved palettes found", vim.log.levels.INFO)
		return
	end

	local buf = vim.api.nvim_create_buf(false, true)
	local lines = {
		"Saved Palettes",
		string.rep("=", 30),
		"",
	}

	for _, name in ipairs(names) do
		local palette_data = palette_mgr.load_palette(name)
		local method = "unknown"
		local count = 0
		if palette_data and palette_data.metadata then
			method = palette_data.metadata.method or "unknown"
			count = palette_data.metadata.color_count or 0
		end
		table.insert(lines, string.format("%s (%s, %d colors)", name, method, count))
	end

	table.insert(lines, "")
	table.insert(lines, "Press 'l' on a line to load, 'd' to delete, 'q' to close")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local width = 50
	local height = #lines
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	}

	vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"l",
		':lua require("colors.palette_commands").load_palette_under_cursor()<CR>',
		{ noremap = true, silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"d",
		':lua require("colors.palette_commands").delete_palette_under_cursor()<CR>',
		{ noremap = true, silent = true }
	)
end

--- Load the palette under the cursor
function M.load_palette_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local name = line:match("^([^%(]+)%s*%(")

	if name then
		name = name:gsub("%s+$", "")
		local palette_data = palette_mgr.load_palette(name)

		if palette_data then
			M.show_loaded_palette(palette_data.colors, name, palette_data.metadata)
		else
			vim.notify("Failed to load palette '" .. name .. "'", vim.log.levels.ERROR)
		end
	end
end

--- Delete the palette under the cursor
function M.delete_palette_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local name = line:match("^([^%(]+)%s*%(")

	if name then
		name = name:gsub("%s+$", "")

		vim.ui.select({ "Yes", "No" }, { prompt = "Delete palette '" .. name .. "'?" }, function(choice)
			if choice == "Yes" then
				local success = palette_mgr.delete_palette(name)
				if success then
					vim.notify("Palette '" .. name .. "' deleted", vim.log.levels.INFO)
					vim.cmd("close")
					M.list_palettes()
				else
					vim.notify("Failed to delete palette", vim.log.levels.ERROR)
				end
			end
		end)
	end
end

--- Show a loaded palette
---@param palette table Array of color objects
---@param name string Palette name
---@param metadata table Palette metadata
function M.show_loaded_palette(palette, name, metadata)
	local buf = vim.api.nvim_create_buf(false, true)
	local method = metadata and metadata.method or "unknown"
	local base = metadata and metadata.base_color or "unknown"
	local lines = {
		"Loaded Palette: " .. name,
		"Generated: " .. method .. " from " .. base,
		string.rep("=", 50),
		"",
	}

	for i, color in ipairs(palette) do
		local hex = string.format("#%06X", color)
		table.insert(lines, string.format("%d. %s", i, hex))
	end

	table.insert(lines, "")
	table.insert(lines, "Press 'e' to export to Lua, 'q' to close")

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

	local width = 50
	local height = #lines
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	}

	vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(
		buf,
		"n",
		"e",
		':lua require("colors.palette_commands").export_current_palette()<CR>',
		{ noremap = true, silent = true }
	)

	vim.api.nvim_buf_set_var(buf, "export_data", {
		palette = palette,
		name = name,
	})
end

--- Export the current palette to Lua code
function M.export_current_palette()
	local buf = vim.api.nvim_get_current_buf()
	local ok, data = pcall(vim.api.nvim_buf_get_var, buf, "export_data")

	if not ok then
		vim.notify("No export data found", vim.log.levels.ERROR)
		return
	end

	local lua_code = palette_mgr.export_palette_to_lua(data.palette, data.name)

	local export_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(export_buf, 0, -1, false, vim.split(lua_code, "\n"))

	local width = 60
	local height = #vim.split(lua_code, "\n") + 2
	local opts = {
		relative = "editor",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		style = "minimal",
		border = "rounded",
	}

	vim.api.nvim_open_win(export_buf, true, opts)
	vim.api.nvim_set_option_value("filetype", "lua", { buf = export_buf })
end

-- Register Neovim commands
vim.api.nvim_create_user_command("PaletteGenerate", function(opts)
	local args = vim.split(opts.args, " ")
	local base_color = args[1] or "red"
	local method = args[2] or "monochromatic"
	local options = { count = tonumber(args[3]) or 5 }

	M.show_palette(base_color, method, options)
end, {
	nargs = "*",
	desc = "Generate and display a color palette",
	complete = function(arg_lead, cmd_line, _)
		local args = vim.split(cmd_line, " ")
		if #args == 2 then
			local names = palette_gen.get_color_names()
			return vim.tbl_filter(function(name)
				return name:lower():find(arg_lead:lower(), 1, true) == 1
			end, names)
		elseif #args == 3 then
			local methods = { "monochromatic", "analogous", "equally" }
			return vim.tbl_filter(function(method)
				return method:find(arg_lead, 1, true) == 1
			end, methods)
		end
		return {}
	end,
})

vim.api.nvim_create_user_command("PaletteList", function()
	M.list_palettes()
end, { desc = "List saved palettes" })

vim.api.nvim_create_user_command("PaletteStats", function()
	local stats = palette_mgr.get_palette_stats()
	vim.notify(
		string.format(
			"Palettes: %d, Colors: %d, Avg size: %.1f",
			stats.total_palettes,
			stats.total_colors,
			stats.average_palette_size
		),
		vim.log.levels.INFO
	)
end, { desc = "Show palette statistics" })

return M
