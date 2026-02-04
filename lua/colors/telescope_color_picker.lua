--- A Neovim plugin that provides an interactive color picker using Telescope.
--- Features include fuzzy search and visual color comparison previews.

local colors = require("colors.colors")
local colors_utils = require("colors.colors_utils")

-- =============================================================================
-- TELESCOPE INTEGRATION
-- =============================================================================
-- Sets up Telescope components for color picker functionality

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- =============================================================================
-- HYBRID COLOR SORTER
-- =============================================================================
-- Custom sorter that combines fuzzy matching for color names with
-- color distance scoring when searching by hex values.

local function hybrid_color_sorter()
	local fuzzy_sorter = sorters.get_generic_fuzzy_sorter()
	return sorters.new({
		scoring_function = function(_, prompt, _, entry)
			if prompt:match("^#") then
				local target_hex = colors_utils.standardize_input_hex(prompt)
				if not target_hex then
					return 1000
				end
				local c = colors_utils.hex_to_int(target_hex)
				if c and entry.color then
					return colors_utils.color_distance(c, entry.color)
				else
					return 1000
				end
			elseif prompt:match("!$") then
				local target_name = prompt:sub(1, -2):lower()
				-- Find the target color by name
				for _, color in ipairs(colors) do
					if color.name:lower() == target_name then
						return colors_utils.color_distance(color.color, entry.color)
					end
				end
				return 1000 -- Target color not found
			end
			return fuzzy_sorter:scoring_function(prompt, _, entry)
		end,
		highlighter = fuzzy_sorter.highlighter,
	})
end

-- =============================================================================
-- DYNAMIC COLOR PREVIEWER
-- =============================================================================
-- Advanced previewer that shows visual color swatches, match accuracy,
-- and contrast checks on black/white backgrounds for selected and target colors.

local dynamic_previewer = previewers.new_buffer_previewer({
	title = "Color Comparison",
	define_preview = function(self, entry, _)
		local bufnr = self.state.bufnr
		local ns_id = vim.api.nvim_create_namespace("telescope_color_preview")
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

		local prompt = action_state.get_current_line()
		local is_hex_mode = prompt:match("^#")
		local is_name_mode = prompt:match("!$")
		local target_hex = colors_utils.standardize_input_hex(prompt)
		local target_color = nil
		local target_name = nil

		if is_name_mode then
			target_name = prompt:sub(1, -2):lower()
			-- Find the target color by name
			for _, color in ipairs(colors) do
				if color.name:lower() == target_name then
					target_color = color
					target_hex = colors_utils.int_to_hex(color.color)
					break
				end
			end
		elseif is_hex_mode and target_hex then
			-- Check if the target hex matches a color in our palette
			local target_int = colors_utils.hex_to_int(target_hex)
			for _, color in ipairs(colors) do
				if color.color == target_int then
					target_color = color
					target_name = color.name
					break
				end
			end
		end

		local lines = {}
		local hl_ops = {}

		-- SECTION A: Visual Comparison (Swatches)
		if (is_hex_mode and target_hex) or (is_name_mode and target_color) then
			-- Mode 1: Side-by-side comparison
			local target_display = target_color and target_color.name or target_hex
			table.insert(lines, string.format("%-18s%-18s", "TARGET: " .. target_display, "SELECTED: " .. entry.name))

			for _ = 1, 3 do
				table.insert(lines, string.rep(" ", 36))

				-- Highlight Left Block (Target)
				assert(type(target_hex) == "string", "target_hex must be a string")
				local input_grp = "PreviewInput_" .. target_hex:gsub("#", "")
				table.insert(hl_ops, {
					group = input_grp,
					fg = target_hex,
					bg = target_hex,
					line = #lines - 1,
					col_start = 0,
					col_end = 18,
				})

				-- Highlight Right Block (Selected)
				local select_grp = "PreviewSelect_" .. entry.hex:gsub("#", "")
				table.insert(hl_ops, {
					group = select_grp,
					fg = entry.hex,
					bg = entry.hex,
					line = #lines - 1,
					col_start = 18,
					col_end = 36,
				})
			end

			-- Match Accuracy
			local c = colors_utils.hex_to_int(target_hex)
			if c then
				local match_percent = colors_utils.color_similarity(c, entry.color)
				table.insert(lines, "")
				table.insert(lines, string.format("Match Accuracy: %.1f%%", match_percent * 100))
			end
		else
			-- Standard Name Mode (Just show the selected color)
			table.insert(lines, "SELECTED COLOR")
			table.insert(lines, string.format("  %s %s", entry.name, entry.hex))

			for _ = 1, 3 do
				table.insert(lines, "  " .. string.rep(" ", 26))
				local select_grp = "PreviewSelect_" .. entry.hex:gsub("#", "")
				table.insert(hl_ops, {
					group = select_grp,
					fg = entry.hex,
					bg = entry.hex,
					line = #lines - 1,
					col_start = 2,
					col_end = 28,
				})
			end
			table.insert(lines, "")
		end

		-- Add a little extra space between sections
		table.insert(lines, "")
		table.insert(lines, string.rep("─", 40))

		-- SECTION B: Contrast Text Checks
		local sample_text = " This is my color !"
		local hl_fg_clean = entry.hex:gsub("#", "")

		-- Header for Contrast on Black/White
		table.insert(lines, "CONTRAST TEXT CHECKS")
		table.insert(lines, string.rep("─", 40))

		-- On Black (Selected Color)
		table.insert(lines, "  " .. entry.name .. " (" .. entry.hex .. ") on Black:")
		table.insert(lines, "  " .. sample_text)
		local group_on_black = "PreviewOnBlack_" .. hl_fg_clean
		table.insert(hl_ops, {
			group = group_on_black,
			fg = entry.hex,
			bg = "#000000",
			line = #lines - 1,
			col_start = 2,
			col_end = -1,
		})

		-- On White (Selected Color)
		table.insert(lines, "  " .. entry.name .. " (" .. entry.hex .. ") on White:")
		table.insert(lines, "  " .. sample_text)
		local group_on_white = "PreviewOnWhite_" .. hl_fg_clean
		table.insert(hl_ops, {
			group = group_on_white,
			fg = entry.hex,
			bg = "#ffffff",
			line = #lines - 1,
			col_start = 2,
			col_end = -1,
		})

		-- SECTION C: Contrast Checks for Target Color
		if (is_hex_mode and target_hex) or (is_name_mode and target_color) then
			assert(type(target_hex) == "string", "target_hex must be a string")
			local target_clean = target_hex:gsub("#", "")

			-- Target Color Header
			table.insert(lines, "")
			table.insert(lines, "TARGET COLOR CONTRAST CHECKS")
			table.insert(lines, string.rep("─", 40))

			-- Target Color on Black
			local target_desc = target_color and target_color.name .. " (" .. target_hex .. ")" or target_hex
			table.insert(lines, "  " .. target_desc .. " on Black:")
			table.insert(lines, "  " .. sample_text)
			local target_on_black = "PreviewTargetOnBlack_" .. target_clean
			table.insert(hl_ops, {
				group = target_on_black,
				fg = target_hex,
				bg = "#000000",
				line = #lines - 1,
				col_start = 2,
				col_end = -1,
			})

			-- Target Color on White
			table.insert(lines, "  " .. target_desc .. " on White:")
			table.insert(lines, "  " .. sample_text)
			local target_on_white = "PreviewTargetOnWhite_" .. target_clean
			table.insert(hl_ops, {
				group = target_on_white,
				fg = target_hex,
				bg = "#ffffff",
				line = #lines - 1,
				col_start = 2,
				col_end = -1,
			})
		end

		-- Final line separator
		table.insert(lines, string.rep("─", 40))

		-- Render and Highlight
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
		for _, op in ipairs(hl_ops) do
			vim.cmd(string.format("highlight %s guifg=%s guibg=%s", op.group, op.fg, op.bg))
			vim.hl.range(bufnr, ns_id, op.group, { op.line, op.col_start }, { op.line, op.col_end })
		end
	end,
})

-- =============================================================================
-- MAIN COLOR PICKER FUNCTION
-- =============================================================================
-- Creates and launches the Telescope color picker with all configured components.
-- Handles user selection and inserts the chosen hex color into the current buffer.

local function pick_colors_dynamic()
	pickers
		.new({}, {
			prompt_title = "Color Picker",
			finder = finders.new_table({
				results = colors,
				entry_maker = function(entry)
					local hex = colors_utils.int_to_hex(entry.color)
					return {
						value = entry,
						display = entry.name .. " " .. hex,
						ordinal = entry.name,
						name = entry.name,
						color = entry.color,
						hex = hex,
					}
				end,
			}),
			sorter = hybrid_color_sorter(),
			previewer = dynamic_previewer,
			attach_mappings = function(prompt_bufnr, _)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					if selection then
						-- Insert the selected hex at the current cursor position
						local hex_code = selection.hex
						vim.api.nvim_put({ hex_code }, "c", true, true)
						vim.notify("Inserted color " .. hex_code)
					end
				end)
				return true
			end,
		})
		:find()
end

-- =============================================================================
-- PLUGIN INITIALIZATION
-- =============================================================================
-- Registers the :HexColors command and exports the color palette as a lookup table.

vim.api.nvim_create_user_command("HexColors", pick_colors_dynamic, {})

-- Create a lookup table mapping color names to hex values
local hex_colors = {}
for _, color in ipairs(colors) do
	hex_colors[color.name] = colors_utils.int_to_hex(color.color)
end

return hex_colors
