--- Palette management: saving, loading, and organizing generated palettes

local M = {}

-- Storage for user-generated palettes
M.saved_palettes = {}

-- File path for persistence
local palette_file = vim.fn.stdpath('config') .. '/palettes.lua'

--- Load palettes from file
local function load_palettes()
  if vim.fn.filereadable(palette_file) == 1 then
    local ok, data = pcall(dofile, palette_file)
    if ok and type(data) == 'table' then
      M.saved_palettes = data
    end
  end
end

--- Save palettes to file
local function save_palettes()
  local lines = {'return {'}
  for name, palette_data in pairs(M.saved_palettes) do
    table.insert(lines, string.format('  ["%s"] = {', name:gsub('"', '\\"')))
    table.insert(lines, '    colors = {')
    for _, color in ipairs(palette_data.colors) do
      table.insert(lines, string.format('      {name="%s", color=0x%06x},', color.name, color.color))
    end
    table.insert(lines, '    },')
    table.insert(lines, '    metadata = {')
    table.insert(lines, string.format('      method="%s",', palette_data.metadata.method))
    table.insert(lines, string.format('      base_color="%s",', palette_data.metadata.base_color))
    table.insert(lines, '      options={},')
    table.insert(lines, string.format('      created_at="%s",', palette_data.metadata.created_at))
    table.insert(lines, string.format('      color_count=%d,', palette_data.metadata.color_count))
    table.insert(lines, '    },')
    table.insert(lines, '  },')
  end
  table.insert(lines, '}')
  vim.fn.writefile(lines, palette_file)
end

-- Load palettes on module load
load_palettes()

--- Save a palette with metadata
---@param palette table Array of color objects
---@param name string Palette name
---@param method string Generation method used
---@param base_color string Base color name
---@param options table Generation options used
---@return boolean Success status
function M.save_palette(palette, name, method, base_color, options)
  if not palette or #palette == 0 then
    return false, "Palette cannot be empty"
  end

  if M.saved_palettes[name] then
    return false, "Palette name already exists"
  end

   M.saved_palettes[name] = {
     colors = palette,
     metadata = {
       method = method,
       base_color = base_color,
       options = options or {},
       created_at = os.date("%Y-%m-%d %H:%M:%S"),
       color_count = #palette
     }
   }

   save_palettes()
   return true
end

--- Load a saved palette
---@param name string Palette name
---@return table|nil Palette data or nil if not found
function M.load_palette(name)
  return M.saved_palettes[name]
end

--- Get all saved palette names
---@return table Array of palette names
function M.get_saved_palette_names()
  local names = {}
  for name, _ in pairs(M.saved_palettes) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

--- Delete a saved palette
---@param name string Palette name
---@return boolean Success status
function M.delete_palette(name)
   if M.saved_palettes[name] then
     M.saved_palettes[name] = nil
     save_palettes()
     return true
   end
   return false
 end

--- Export palette to Lua code string
---@param palette table Array of color objects
---@param name string Palette name
---@return string Lua code string
function M.export_palette_to_lua(palette, name)
  local code = string.format("-- Generated palette: %s\nlocal %s = {\n", name, name:gsub("[^%w_]", "_"))

  for i, color in ipairs(palette) do
    local hex = string.format("0x%06x", color.color)
    code = code .. string.format("  {name=\"%s\", color=%s}", color.name, hex)
    if i < #palette then
      code = code .. ","
    end
    code = code .. "\n"
  end

  code = code .. "}\nreturn " .. name:gsub("[^%w_]", "_")
  return code
end

--- Import palette from Lua table
---@param lua_code string Lua code defining a palette table
---@param name string Name to save the palette as
---@return boolean Success status
---@return string Error message if failed
function M.import_palette_from_lua(lua_code, name)
  -- Basic validation - this is a simplified implementation
  -- In a real implementation, you'd want proper Lua parsing

  if M.saved_palettes[name] then
    return false, "Palette name already exists"
  end

  -- Extract colors from the Lua code (simplified parsing)
  local colors = {}
  for line in lua_code:gmatch("[^\r\n]+") do
    local name_match, color_match = line:match('{name="([^"]+)",%s*color=(0x%x+)}')
    if name_match and color_match then
      table.insert(colors, {
        name = name_match,
        color = tonumber(color_match)
      })
    end
  end

  if #colors == 0 then
    return false, "No valid colors found in Lua code"
  end

   M.saved_palettes[name] = {
     colors = colors,
     metadata = {
       method = "imported",
       base_color = "unknown",
       options = {},
       created_at = os.date("%Y-%m-%d %H:%M:%S"),
       color_count = #colors
     }
   }

   save_palettes()
   return true
end

--- Get palette statistics
---@return table Statistics about saved palettes
function M.get_palette_stats()
  local stats = {
    total_palettes = 0,
    total_colors = 0,
    methods_used = {},
    average_palette_size = 0
  }

  for name, palette_data in pairs(M.saved_palettes) do
    stats.total_palettes = stats.total_palettes + 1
    stats.total_colors = stats.total_colors + palette_data.metadata.color_count

    local method = palette_data.metadata.method
    stats.methods_used[method] = (stats.methods_used[method] or 0) + 1
  end

  if stats.total_palettes > 0 then
    stats.average_palette_size = stats.total_colors / stats.total_palettes
  end

  return stats
end

return M