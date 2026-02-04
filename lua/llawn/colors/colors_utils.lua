--- Color utility functions shared across plugins.
--- Provides common color conversion and manipulation utilities.

local M = {}

--- Converts an integer color value to RGB components.
--- @param int integer: The color as an integer (e.g., 0xff0000)
--- @return number r, number g, number b: The red, green, and blue components (0-255)
function M.int_to_rgb(int)
	local r = bit.band(bit.rshift(int, 16), 255)
	local g = bit.band(bit.rshift(int, 8), 255)
	local b = bit.band(int, 255)
	return r, g, b
end

--- Converts an integer color value to a hex string.
--- @param int integer: The color as an integer (e.g., 0xff0000)
--- @return string: The hex color string (e.g., "#ff0000")
function M.int_to_hex(int)
	return string.format("#%06x", int)
end

--- Converts an RGB color value to an integer color value
--- @param r number: Red component of color (0-255)
--- @param g number: Green component of color (0-255)
--- @param b number: Blue component of color (0-255)
--- @return integer int: The color as an integer (e.g., 0xff0000)
function M.rgb_to_int(r, g, b)
	local int = bit.bor(bit.lshift(r, 16), bit.lshift(g, 8), b)
	return int
end

--- Converts RGB color values to a hex color string
--- @param r number: Red component of color (0-255)
--- @param g number: Green component of color (0-255)
--- @param b number: Blue component of color (0-255)
--- @return string: The hex color string (e.g., "#ff0000")
function M.rgb_to_hex(r, g, b)
	return string.format("#%02x%02x%02x", r, g, b)
end

--- Standardize hex color to full 6-digit format, or pads with zeros if needed.
--- @param hex string: The hex color string (e.g., "#f00", "#ff0000")
--- @return string|nil: The standardize hex string, or nil if invalid
function M.standardize_input_hex(hex)
	if not hex then
		return nil
	end
	hex = hex:lower()
	local h_std = nil

	-- handle #hex string
	if hex:match("^#") then
		local h = hex:sub(2)
		if #h == 6 and h:match("^%x+$") then
			h_std = hex
		elseif #h == 3 and h:match("^%x+$") then
			h_std = "#" .. h:sub(1, 1):rep(2) .. h:sub(2, 2):rep(2) .. h:sub(3, 3):rep(2)
		elseif #h < 6 and h:match("^%x*") then
			h_std = "#" .. h .. string.rep("0", 6 - #h)
		end
	-- handle 0x string
	elseif hex:match("^0x%x+$") then
		local int = tonumber(hex, 16)
		if int and int <= 0xffffff then
			h_std = string.format("#%06x", int)
		end
	end
	return h_std
end

--- Converts a hex color string to an integer color value.
--- @param hex string: The hex color string (e.g., "#ff0000", "0xff0000")
--- @return integer|nil int: The color as an integer, or nil if invalid
function M.hex_to_int(hex)
	local h_std = M.standardize_input_hex(hex)
	if not h_std then
		return nil
	end

	local int = tonumber(h_std:sub(2), 16)
	if int and int <= 0xffffff then
		return int
	end

	return nil
end

--- Converts a hex color string to RGB components
--- @param hex string: The hex color string (e.g., "#ff0000", "0xff0000")
--- @return number|nil r, number|nil g, number|nil b: The red, green, and blue components (0-255)
function M.hex_to_rgb(hex)
	local int = M.hex_to_int(hex)
	if int then
		return M.int_to_rgb(int)
	end
	return nil
end

--- Calculates the Euclidean distance between two RGB colors.
--- @param r1 number: Red component of first color (0-255)
--- @param g1 number: Green component of first color (0-255)
--- @param b1 number: Blue component of first color (0-255)
--- @param r2 number: Red component of second color (0-255)
--- @param g2 number: Green component of second color (0-255)
--- @param b2 number: Blue component of second color (0-255)
--- @return number: The distance between the two colors
function M.rgb_distance(r1, g1, b1, r2, g2, b2)
	return math.sqrt((r1 - r2) ^ 2 + (g1 - g2) ^ 2 + (b1 - b2) ^ 2)
end

--- @param c1 integer: The color as an integer (e.g., 0xff0000)
--- @param c2 integer: The color as an integer (e.g., 0xff0000)
--- @return number: The distance between the two colors
function M.color_distance(c1, c2)
	local r1, g1, b1 = M.int_to_rgb(c1)
	local r2, g2, b2 = M.int_to_rgb(c2)
	return M.rgb_distance(r1, g1, b1, r2, g2, b2)
end

--- Calculates the similarity score between two colors.
--- The score ranges from 0 to 1
--- 0 indicates no similarity and 1 indicates that the colors are identical.
--- @param c1 integer: The color as an integer (e.g., 0xff0000)
--- @param c2 integer: The color as an integer (e.g., 0xff0000)
--- @return number: The matching value between the two colors
function M.color_similarity(c1, c2)
	local max_dist = math.sqrt(3) * 255
	local dist = M.color_distance(c1, c2)
	return math.max(0, 1 - (dist / max_dist))
end

--- Converts RGB values to HSL.
--- @param r number: Red component (0-255)
--- @param g number: Green component (0-255)
--- @param b number: Blue component (0-255)
--- @return number h, number s, number l: Hue (0-1), Saturation (0-1), Lightness (0-1)
function M.rgb_to_hsl(r, g, b)
	r, g, b = r / 255, g / 255, b / 255
	local max = math.max(r, g, b)
	local min = math.min(r, g, b)
	local h, s, l = 0, 0, (max + min) / 2

	if max ~= min then
		local d = max - min
		s = l > 0.5 and d / (2 - max - min) or d / (max + min)
		if max == r then
			h = (g - b) / d + (g < b and 6 or 0)
		elseif max == g then
			h = (b - r) / d + 2
		else
			h = (r - g) / d + 4
		end
		h = h / 6
	end

	return h, s, l
end

--- Converts HSL values to RGB.
--- @param h number: Hue (0-1)
--- @param s number: Saturation (0-1)
--- @param l number: Lightness (0-1)
--- @return number r, number g, number b: Red, Green, Blue components (0-255)
function M.hsl_to_rgb(h, s, l)
	local r, g, b
	if s == 0 then
		r, g, b = l, l, l
	else
		local function hue2rgb(p, q, t)
			if t < 0 then
				t = t + 1
			end
			if t > 1 then
				t = t - 1
			end
			if t < 1 / 6 then
				return p + (q - p) * 6 * t
			end
			if t < 1 / 2 then
				return q
			end
			if t < 2 / 3 then
				return p + (q - p) * (2 / 3 - t) * 6
			end
			return p
		end
		local q = l < 0.5 and l * (1 + s) or l + s - l * s
		local p = 2 * l - q
		r = hue2rgb(p, q, h + 1 / 3)
		g = hue2rgb(p, q, h)
		b = hue2rgb(p, q, h - 1 / 3)
	end
	return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

--- Get the Relative Luminance from RGB
--- @param r number: Red component (0-255)
--- @param g number: Green component (0-255)
--- @param b number: Blue component (0-255)
--- @return number y: Relative lumninance (0-1)
function M.relative_luminance(r, g, b)
	-- Convert RGB values to [0, 1]
	local R = r / 255
	local G = g / 255
	local B = b / 255

	-- Function to calculate linear value
	local function toLinear(c)
		if c <= 0.04045 then
			return c / 12.92
		else
			return ((c + 0.055) / 1.055) ^ 2.4
		end
	end

	-- Calculate linear RGB values
	local R_linear = toLinear(R)
	local G_linear = toLinear(G)
	local B_linear = toLinear(B)

	-- Calculate relative luminance
	local y = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear

	return y
end

return M
