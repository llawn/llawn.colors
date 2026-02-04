--- @brief Configuration module for colors plugin
--- Contains default settings and configuration management

local M = {}

-- Default configuration
M.defaults = {
	-- Color highlighting settings
	highlighting = {
		enabled = true,
		max_lines = 5000, -- Maximum lines to process for performance
		enable_virtual_text = true,
		enable_background_highlights = true,
	},

	-- Palette file settings
	palette = {
		file_path = vim.fn.stdpath("data") .. "/palettes.lua",
	},

	-- Key mappings
	keymaps = {
		toggle_highlight = "<leader>ct",
	},

	-- Autocommand settings
	autocmds = {
		events = { "BufEnter", "BufRead", "TextChanged", "TextChangedI" },
		pattern = "*",
	},
}

-- Current configuration (starts with defaults, merged with user opts)
M.config = vim.deepcopy(M.defaults)

--- Merge user options with default configuration
--- @param opts table|nil User configuration options
--- @return table Merged configuration
function M.setup(opts)
	opts = opts or {}

	-- Deep merge user options with defaults
	M.config = vim.tbl_deep_extend("force", M.defaults, opts)

	return M.config
end

--- Get current configuration value
--- @param key string Dot-separated key path (e.g., "highlighting.enabled")
--- @return any Configuration value
function M.get(key)
	local keys = vim.split(key, ".", { plain = true })
	local value = M.config

	for _, k in ipairs(keys) do
		value = value[k]
		if value == nil then
			return nil
		end
	end

	return value
end

--- Set configuration value
--- @param key string Dot-separated key path
--- @param val any Value to set
function M.set(key, val)
	local keys = vim.split(key, ".", { plain = true })
	local target = M.config

	for i = 1, #keys - 1 do
		if target[keys[i]] == nil then
			target[keys[i]] = {}
		end
		target = target[keys[i]]
	end

	target[keys[#keys]] = val
end

--- Reset configuration to defaults
function M.reset()
	M.config = vim.deepcopy(M.defaults)
end

return M
