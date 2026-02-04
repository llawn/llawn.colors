--- Color palette generation algorithms
--- Generates harmonious color palettes from existing color database

local colors = require("colors.colors")
local utils = require("colors.colors_utils")

local M = {}

--- @alias PaletteDirection "both" | "up" | "down"

--- @class PaletteOptionsBase
--- @field count? number The number of colors to generate (default: 5)
--- @field step_size? number The increment per step
--- @field direction? PaletteDirection (default: "both")

--- @class PaletteOptionsMonochromatic : PaletteOptionsBase
--- @field step_size? number The lightness increment per step (default: 10)

--- Generate monochromatic palette (lightness_variation)
--- @param base_color Color Base color from palette
--- @param options? PaletteOptionsMonochromatic
--- @return number[] # palette List of color integers
--- @return number # base_index The index of the original base color in the table
function M.generate_monochromatic(base_color, options)
	options = options or {}

	local count = options.count or 5
	assert(type(count) == "number" and count > 0, "count must be a positive number.")

	local step_size = (options.step_size or 10) % 100
	assert(type(step_size) == "number", "step_size must be a number.")

	local direction = options.direction or "both"
	assert(type(direction) == "string", "direction must be a string.")
	direction = direction:lower()
	local valid_directions = { up = true, down = true, both = true }
	assert(valid_directions[direction], "direction must be 'up', 'down', or 'both'.")

	local palette = {}
	local base_index = 1

	local r, g, b = utils.int_to_rgb(base_color.color)
	local h, s, l = utils.rgb_to_hsl(r, g, b)

	local start_offset = 0
	if direction == "both" then
		start_offset = -math.floor(count / 2)
	elseif direction == "down" then
		start_offset = -(count - 1)
	end

	for i = 0, count - 1 do
		local offset = (start_offset + i) * step_size
		if offset == 0 then
			base_index = i + 1
		end
		local new_l = ((l * 100 + offset) % 100) / 100
		local new_r, new_g, new_b = utils.hsl_to_rgb(h, s, new_l)
		local color_int = utils.rgb_to_int(new_r, new_g, new_b)
		table.insert(palette, color_int)
	end

	return palette, base_index
end

--- @class PaletteOptionsAnalogous : PaletteOptionsBase
--- @field step_size? number The hue increment per step (default: 15)

--- Generate analogous palette (hue_variation)
--- @param base_color Color Base color from palette
--- @param options? PaletteOptionsAnalogous
--- @return number[] # palette List of color integers
--- @return number # base_index The index of the original base color in the table
function M.generate_analogous(base_color, options)
	options = options or {}

	local count = options.count or 5
	assert(type(count) == "number" and count > 0, "count must be a positive number.")

	local step_size = (options.step_size or 15) % 360
	assert(type(step_size) == "number", "step_size must be a number.")

	local direction = options.direction or "both"
	assert(type(direction) == "string", "direction must be a string.")
	direction = direction:lower()
	local valid_directions = { up = true, down = true, both = true }
	assert(valid_directions[direction], "direction must be 'up', 'down', or 'both'.")

	local palette = {}
	local base_index = 1

	local r, g, b = utils.int_to_rgb(base_color.color)
	local h, s, l = utils.rgb_to_hsl(r, g, b)

	local start_offset = 0
	if direction == "both" then
		start_offset = -math.floor(count / 2)
	elseif direction == "down" then
		start_offset = -(count - 1)
	end

	for i = 0, count - 1 do
		local offset = (start_offset + i) * step_size
		if offset == 0 then
			base_index = i + 1
		end
		local new_h = ((h * 360 + offset) % 360) / 360
		local new_r, new_g, new_b = utils.hsl_to_rgb(new_h, s, l)
		local color_int = utils.rgb_to_int(new_r, new_g, new_b)
		table.insert(palette, color_int)
	end

	return palette, base_index
end

--- @class PaletteOptionsEqually
--- @field count? number The number of colors to generate (default: 2)

--- Generate equally space colors
--- @param base_color Color Base color from palette
--- @param options PaletteOptionsEqually
--- @return number[] # palette List of color integers
--- @return number # base_index The index of the original base color in the table
function M.generate_equally(base_color, options)
	options = options or {}

	local count = options.count or 2
	assert(type(count) == "number" and count > 0, "count must be a positive number.")

	local palette = { base_color.color }
	local base_index = 1

	local h_step = 360 / count

	local r, g, b = utils.int_to_rgb(base_color.color)
	local h, s, l = utils.rgb_to_hsl(r, g, b)

	for i = 1, count - 1 do
		local new_h = ((h * 360 + i * h_step) % 360) / 360
		local new_r, new_g, new_b = utils.hsl_to_rgb(new_h, s, l)
		local color_int = utils.rgb_to_int(new_r, new_g, new_b)
		table.insert(palette, color_int)
	end

	return palette, base_index
end

--- Generate palette using specified method
--- @param base_color_name string Name of base color from palette
--- @param method string Generation method ("monochromatic", "analogous", "equally")
--- @param options table Optional parameters
--- @return number[] # palette List of color integers
--- @return number # base_index The index of the original base color in the table
function M.generate_palette(base_color_name, method, options)
	options = options or {}
	method = method:lower()
	local valid_methods = {
		monochromatic = true,
		analogous = true,
		equally = true,
	}
	assert(valid_methods[method], "method must be 'monochromatic', 'analogous', or 'equally'.")

	-- Find base color
	local base_color = nil
	local name = base_color_name:lower()
	for _, color in ipairs(colors) do
		local hex_value = utils.int_to_hex(color.color)
		if color.name:lower() == name or hex_value == name then
			base_color = color
			break
		end
	end

	assert(base_color ~= nil, "you must passed a valid base_color_name")
	-- Generate based on method
	local func = nil
	if method == "monochromatic" then
		func = M.generate_monochromatic
	elseif method == "analogous" then
		func = M.generate_analogous
	elseif method == "equally" then
		func = M.generate_equally
	end
	assert(func ~= nil)
	return func(base_color, options)
end

--- Check if contrast ratio meets WCAG standards
---@param ratio number Contrast ratio
---@param level string "AA" or "AAA"
---@param size string "normal" or "large"
---@return boolean Whether it passes the standard
function M.check_wcag_compliance(ratio, level, size)
	if level == "AAA" then
		return size == "large" and ratio >= 4.5 or ratio >= 7.0
	else -- AA level
		return size == "large" and ratio >= 3.0 or ratio >= 4.5
	end
end

--- Analyze palette accessibility
---@param palette number[] Array of color integers
---@return table # Accessibility analysis with contrast ratios and compliance
function M.analyze_palette_accessibility(palette)
	local analysis = {
		contrast_ratios = {},
		compliance = {
			aa_normal = { passed = 0, total = 0 },
			aa_large = { passed = 0, total = 0 },
			aaa_normal = { passed = 0, total = 0 },
			aaa_large = { passed = 0, total = 0 },
		},
		recommendations = {},
	}

	local n = #palette
	if n < 2 then
		return analysis
	end

	-- Calculate all pairwise contrast ratios
	for i = 1, n do
		local color_i = palette[i]
		local hex_i = utils.int_to_hex(color_i)

		for j = i + 1, n do
			local color_j = palette[j]
			local hex_j = utils.int_to_hex(color_j)

			-- Assuming get_contrast_ratio takes two color integers
			local ratio = utils.get_contrast_ratio(color_i, color_j)
			local pair_key = string.format("%s | %s", hex_i, hex_j)

			analysis.contrast_ratios[pair_key] = ratio

			-- Update Totals
			analysis.compliance.aa_normal.total = analysis.compliance.aa_normal.total + 1
			analysis.compliance.aa_large.total = analysis.compliance.aa_large.total + 1
			analysis.compliance.aaa_normal.total = analysis.compliance.aaa_normal.total + 1
			analysis.compliance.aaa_large.total = analysis.compliance.aaa_large.total + 1

			-- Check and Update Passes
			if M.check_wcag_compliance(ratio, "AA", "normal") then
				analysis.compliance.aa_normal.passed = analysis.compliance.aa_normal.passed + 1
			end
			if M.check_wcag_compliance(ratio, "AA", "large") then
				analysis.compliance.aa_large.passed = analysis.compliance.aa_large.passed + 1
			end
			if M.check_wcag_compliance(ratio, "AAA", "normal") then
				analysis.compliance.aaa_normal.passed = analysis.compliance.aaa_normal.passed + 1
			end
			if M.check_wcag_compliance(ratio, "AAA", "large") then
				analysis.compliance.aaa_large.passed = analysis.compliance.aaa_large.passed + 1
			end
		end
	end

	-- Generate recommendations
	local total_pairs = analysis.compliance.aa_normal.total
	if total_pairs > 0 then
		local aa_normal_rate = analysis.compliance.aa_normal.passed / total_pairs
		if aa_normal_rate < 0.7 then
			table.insert(
				analysis.recommendations,
				"Consider increasing contrast between colors for better AA compliance."
			)
		end

		if analysis.compliance.aaa_normal.passed == 0 then
			table.insert(
				analysis.recommendations,
				"No color pairs meet AAA standards—consider adding a very light or very dark color."
			)
		end
	end

	return analysis
end

return M
