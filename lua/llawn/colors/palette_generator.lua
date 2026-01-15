--- Color palette generation algorithms
--- Generates harmonious color palettes from existing color database

local colors = require('llawn.colors.colors')
local colors_utils = require('llawn.colors.colors_utils')

local M = {}

--- Convert RGB to HSL for color calculations
local function rgb_to_hsl(r, g, b)
  r, g, b = r/255, g/255, b/255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, l = 0, 0, (max + min) / 2

  if max ~= min then
    local d = max - min
    s = l > 0.5 and d / (2 - max - min) or d / (max + min)

    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h * 360, s * 100, l * 100
end

--- Convert HSL to RGB
local function hsl_to_rgb(h, s, l)
  h, s, l = h / 360, s / 100, l / 100
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l
  else
    local function hue2rgb(p, q, t)
      if t < 0 then t = t + 1 end
      if t > 1 then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end

    local q = l < 0.5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end

  return math.floor(r * 255 + 0.5), math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5)
end

--- Find closest color in palette to given HSL values
local function find_closest_color(target_h, target_s, target_l)
  local min_distance = math.huge
  local closest_color = nil

  for _, color in ipairs(colors) do
    local r, g, b = colors_utils.int_to_rgb(color.color)
    local h, s, l = rgb_to_hsl(r, g, b)

    -- Calculate color distance (simplified)
    local dh = math.min(math.abs(h - target_h), 360 - math.abs(h - target_h)) / 180
    local ds = math.abs(s - target_s) / 100
    local dl = math.abs(l - target_l) / 100

    local distance = math.sqrt(dh*dh + ds*ds + dl*dl)

    if distance < min_distance then
      min_distance = distance
      closest_color = color
    end
  end

  return closest_color
end

--- Generate monochromatic palette (variations of same hue)
---@param base_color table Base color from palette
---@param count number Number of colors to generate
---@param options table Optional parameters (lightness_variation, saturation_variation)
---@return table Generated palette
function M.generate_monochromatic(base_color, count, options)
  options = options or {}
  local lightness_variation = options.lightness_variation or 60
  local saturation_variation = options.saturation_variation or 0.2

  local r, g, b = colors_utils.int_to_rgb(base_color.color)
  local h, base_s, base_l = rgb_to_hsl(r, g, b)

  local palette = {base_color}

  for i = 1, count - 1 do
    -- Vary lightness across the range
    local lightness_factor = (i - 1) / (count - 2) -- 0 to 1
    local new_l = math.max(5, math.min(95, base_l + (lightness_factor - 0.5) * lightness_variation))

    -- Optionally vary saturation slightly
    local saturation_factor = 1 + (math.random() - 0.5) * saturation_variation
    local new_s = math.max(10, math.min(100, base_s * saturation_factor))

    table.insert(palette, find_closest_color(h, new_s, new_l))
  end

  return palette
end

--- Generate analogous palette (adjacent colors on color wheel)
---@param base_color table Base color from palette
---@param count number Number of colors to generate
---@return table Generated palette
function M.generate_analogous(base_color, count)
  local r, g, b = colors_utils.int_to_rgb(base_color.color)
  local base_h, s, l = rgb_to_hsl(r, g, b)

  local palette = {}
  local hue_step = 30 -- Degrees between colors

  for i = 1, count do
    local hue_offset = (i - math.ceil(count/2)) * hue_step
    local new_h = (base_h + hue_offset) % 360

    local closest = find_closest_color(new_h, s, l)
    table.insert(palette, closest)
  end

  return palette
end

--- Generate complementary palette (opposite colors)
---@param base_color table Base color from palette
---@param count number Number of colors to generate
---@return table Generated palette
function M.generate_complementary(base_color, count)
  local r, g, b = colors_utils.int_to_rgb(base_color.color)
  local base_h, s, l = rgb_to_hsl(r, g, b)

  local palette = {base_color}

  if count > 1 then
    -- Add complementary color (180 degrees opposite)
    local comp_h = (base_h + 180) % 360
    local complementary = find_closest_color(comp_h, s, l)
    table.insert(palette, complementary)

    -- Add variations if more colors requested
    for i = 3, count do
      if i % 2 == 1 then
        -- Add variation of base color
        local variation = find_closest_color(base_h, s * 0.7, l * 0.8 + math.random() * 0.4)
        table.insert(palette, variation)
      else
        -- Add variation of complementary
        local variation = find_closest_color(comp_h, s * 0.7, l * 0.8 + math.random() * 0.4)
        table.insert(palette, variation)
      end
    end
  end

  return palette
end

--- Generate triadic palette (three equally spaced colors)
---@param base_color table Base color from palette
---@param count number Number of colors to generate
---@return table Generated palette
function M.generate_triadic(base_color, count)
  local r, g, b = colors_utils.int_to_rgb(base_color.color)
  local base_h, s, l = rgb_to_hsl(r, g, b)

  local palette = {base_color}

  for i = 1, 2 do
    local new_h = (base_h + i * 120) % 360
    local triadic_color = find_closest_color(new_h, s, l)
    table.insert(palette, triadic_color)
  end

  -- Fill remaining slots with variations
  while #palette < count do
    local base_idx = math.random(#palette)
    local base_color_in_palette = palette[base_idx]
    local r2, g2, b2 = colors_utils.int_to_rgb(base_color_in_palette.color)
    local h2, s2, l2 = rgb_to_hsl(r2, g2, b2)

    local variation = find_closest_color(h2, s2 * 0.8, l2 * 0.6 + math.random() * 0.8)
    table.insert(palette, variation)
  end

  return palette
end

--- Generate tetradic palette (four colors forming square on color wheel)
---@param base_color table Base color from palette
---@param count number Number of colors to generate
---@return table Generated palette
function M.generate_tetradic(base_color, count)
  local r, g, b = colors_utils.int_to_rgb(base_color.color)
  local base_h, s, l = rgb_to_hsl(r, g, b)

  local palette = {base_color}

  -- Tetradic colors are 90 degrees apart (square)
  for i = 1, 3 do
    local new_h = (base_h + i * 90) % 360
    local tetradic_color = find_closest_color(new_h, s, l)
    table.insert(palette, tetradic_color)
  end

  -- Fill remaining slots with variations
  while #palette < count do
    local base_idx = ((#palette - 1) % 4) + 1
    local base_color_in_palette = palette[base_idx]
    local r2, g2, b2 = colors_utils.int_to_rgb(base_color_in_palette.color)
    local h2, s2, l2 = rgb_to_hsl(r2, g2, b2)

    local variation = find_closest_color(h2, s2 * 0.9, l2 * 0.8 + math.random() * 0.4)
    table.insert(palette, variation)
  end

  return palette
end

--- Generate split-complementary palette (base + two adjacent to complementary)
---@param base_color table Base color from palette
---@param count number Number of colors to generate
---@return table Generated palette
function M.generate_split_complementary(base_color, count)
  local r, g, b = colors_utils.int_to_rgb(base_color.color)
  local base_h, s, l = rgb_to_hsl(r, g, b)

  local palette = {base_color}

  -- Split complementary: base + two colors adjacent to complementary
  local comp_h = (base_h + 180) % 360
  local split1_h = (comp_h - 30) % 360
  local split2_h = (comp_h + 30) % 360

  local split1 = find_closest_color(split1_h, s, l)
  local split2 = find_closest_color(split2_h, s, l)

  table.insert(palette, split1)
  table.insert(palette, split2)

  -- Fill remaining with variations
  while #palette < count do
    local variation = find_closest_color(base_h, s * 0.8, l * 0.7 + math.random() * 0.6)
    table.insert(palette, variation)
  end

  return palette
end

--- Generate palette using specified method
---@param base_color_name string Name of base color from palette
---@param method string Generation method ("monochromatic", "analogous", "complementary", "triadic", "tetradic", "split_complementary")
---@param count number Number of colors to generate
---@param options table Optional parameters (saturation_variation, lightness_variation)
---@return table Generated palette or nil if base color not found
function M.generate_palette(base_color_name, method, count, options)
  options = options or {}

  -- Find base color
  local base_color = nil
  for _, color in ipairs(colors) do
    if color.name:lower() == base_color_name:lower() then
      base_color = color
      break
    end
  end

  if not base_color then
    return nil -- Base color not found
  end

  -- Generate based on method
  if method == "monochromatic" then
    return M.generate_monochromatic(base_color, count, options)
  elseif method == "analogous" then
    return M.generate_analogous(base_color, count, options)
  elseif method == "complementary" then
    return M.generate_complementary(base_color, count, options)
  elseif method == "triadic" then
    return M.generate_triadic(base_color, count, options)
  elseif method == "tetradic" then
    return M.generate_tetradic(base_color, count, options)
  elseif method == "split_complementary" then
    return M.generate_split_complementary(base_color, count, options)
  else
    return {base_color} -- Default to just the base color
  end
end

--- Get all available color names for UI
---@return table List of color names
function M.get_color_names()
  local names = {}
  for _, color in ipairs(colors) do
    table.insert(names, color.name)
  end
  return names
end

--- Get color by name
---@param name string Color name
---@return table|nil Color object or nil if not found
function M.get_color_by_name(name)
  for _, color in ipairs(colors) do
    if color.name:lower() == name:lower() then
      return color
    end
  end
  return nil
end

--- Calculate relative luminance of a color (WCAG formula)
---@param color_int integer Color as integer
---@return number Luminance value between 0 and 1
function M.get_relative_luminance(color_int)
  local r, g, b = colors_utils.int_to_rgb(color_int)
  r, g, b = r / 255, g / 255, b / 255

  -- Apply gamma correction
  local function gamma_correct(c)
    return c <= 0.03928 and c / 12.92 or math.pow((c + 0.055) / 1.055, 2.4)
  end

  r, g, b = gamma_correct(r), gamma_correct(g), gamma_correct(b)

  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

--- Calculate contrast ratio between two colors (WCAG)
---@param color1_int integer First color as integer
---@param color2_int integer Second color as integer
---@return number Contrast ratio (1.0 to 21.0+)
function M.get_contrast_ratio(color1_int, color2_int)
  local l1 = M.get_relative_luminance(color1_int)
  local l2 = M.get_relative_luminance(color2_int)

  local lighter = math.max(l1, l2)
  local darker = math.min(l1, l2)

  return (lighter + 0.05) / (darker + 0.05)
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
---@param palette table Array of color objects
---@return table Accessibility analysis with contrast ratios and compliance
function M.analyze_palette_accessibility(palette)
  local analysis = {
    contrast_ratios = {},
    compliance = {
      aa_normal = {passed = 0, total = 0},
      aa_large = {passed = 0, total = 0},
      aaa_normal = {passed = 0, total = 0},
      aaa_large = {passed = 0, total = 0}
    },
    recommendations = {}
  }

  -- Calculate all pairwise contrast ratios
  for i = 1, #palette do
    for j = i + 1, #palette do
      local ratio = M.get_contrast_ratio(palette[i].color, palette[j].color)
      local pair_key = string.format("%s/%s", palette[i].name, palette[j].name)
      analysis.contrast_ratios[pair_key] = ratio

      -- Check compliance for each standard
      local aa_normal = M.check_wcag_compliance(ratio, "AA", "normal")
      local aa_large = M.check_wcag_compliance(ratio, "AA", "large")
      local aaa_normal = M.check_wcag_compliance(ratio, "AAA", "normal")
      local aaa_large = M.check_wcag_compliance(ratio, "AAA", "large")

      analysis.compliance.aa_normal.total = analysis.compliance.aa_normal.total + 1
      analysis.compliance.aa_large.total = analysis.compliance.aa_large.total + 1
      analysis.compliance.aaa_normal.total = analysis.compliance.aaa_normal.total + 1
      analysis.compliance.aaa_large.total = analysis.compliance.aaa_large.total + 1

      if aa_normal then analysis.compliance.aa_normal.passed = analysis.compliance.aa_normal.passed + 1 end
      if aa_large then analysis.compliance.aa_large.passed = analysis.compliance.aa_large.passed + 1 end
      if aaa_normal then analysis.compliance.aaa_normal.passed = analysis.compliance.aaa_normal.passed + 1 end
      if aaa_large then analysis.compliance.aaa_large.passed = analysis.compliance.aaa_large.passed + 1 end
    end
  end

  -- Generate recommendations
  local aa_normal_rate = analysis.compliance.aa_normal.passed / analysis.compliance.aa_normal.total
  if aa_normal_rate < 0.7 then
    table.insert(analysis.recommendations, "Consider increasing contrast between colors for better AA compliance")
  end

  if analysis.compliance.aaa_normal.passed == 0 then
    table.insert(analysis.recommendations, "No color pairs meet AAA standards - consider using higher contrast colors")
  end

  return analysis
end

return M