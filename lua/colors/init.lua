-- Main entry point for colors plugin
local M = {}

-- Core modules
local colors = require("colors.colors")
local palette_manager = require("colors.palette_manager")
local palette_commands = require("colors.palette_commands")
local colors_highlighter = require("colors.colors_highlighter")
local conf = require("colors.conf")

-- Export main functionality
M.colors = colors
M.palette_manager = palette_manager
M.generate_palette = palette_manager.generate_palette
M.list_palettes = palette_manager.list_palettes
M.get_palette_stats = palette_manager.get_palette_stats

-- Setup function to initialize the plugin
function M.setup(opts)
	-- Initialize configuration
	conf.setup(opts)

	-- Set up commands
	palette_commands.setup()

	-- Set up highlighting
	colors_highlighter.setup()
end

return M
