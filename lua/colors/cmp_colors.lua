local colors = require("colors.colors")
local colors_utils = require("colors.colors_utils")

local M = {}

local function parse_cmd_args(line)
	local args = {}
	for m in line:gmatch('%b""') do
		table.insert(args, m)
	end
	local clean_line = line:gsub('%b""', "")
	for m in clean_line:gmatch("%S+") do
		table.insert(args, m)
	end
	return args
end

local function get_color_items(input, use_hex_insert)
	local items = {}
	local cmp = require("cmp")
	local search_term = input:gsub('^"', ""):gsub('"$', ""):gsub("^#", ""):lower()

	for _, color_entry in ipairs(colors) do
		if color_entry.name:lower():find(search_term, 1, true) then
			local hex = colors_utils.int_to_hex(color_entry.color)
			local insert_text = use_hex_insert and hex or color_entry.name

			if not use_hex_insert and insert_text:find(" ") then
				insert_text = '"' .. insert_text .. '"'
			end

			table.insert(items, {
				label = color_entry.name,
				filterText = color_entry.name,
				insertText = insert_text,
				-- Forced to Color kind so the formatter catches it
				kind = cmp.lsp.CompletionItemKind.Color,
				documentation = hex,
			})
		end
	end
	return items
end

local source = {}
function source:complete(params, callback)
	local line = params.context.cursor_before_line
	local input = line:match("[%w_%s#]+$") or ""
	if input == " " or input == "" then
		return callback({})
	end
	callback(get_color_items(input, true))
end

function source:get_keyword_pattern()
	return [[\%(\w\|#\|\s\)*]]
end

function M.format(entry, vim_item)
	local doc = entry.completion_item.documentation
	local hex = type(doc) == "table" and doc.value or doc

	if (entry.source.name == "colors" or vim_item.kind == "Color") and type(hex) == "string" and hex:match("^#%x+") then
		local color_int = colors_utils.hex_to_int(hex)
		if color_int then
			local hl_group = string.format("CmpColor_%06x", color_int)
			local r, g, b = colors_utils.int_to_rgb(color_int)
			local luminance = colors_utils.relative_luminance(r, g, b)
			local fg = luminance > 0.5 and "#000000" or "#ffffff"

			vim.api.nvim_set_hl(0, hl_group, { fg = fg, bg = hex, default = true })

			-- This sets the colored block you see in the buffer
			vim_item.menu = " " .. hex .. " "
			vim_item.menu_hl_group = hl_group
			-- Ensure Kind is set to Color for the icon
			vim_item.kind = "Color"
		end
	end
	return vim_item
end

local palette_source = {}
function palette_source.new()
	return setmetatable({}, { __index = palette_source })
end

function palette_source:complete(params, callback)
	local line = params.context.cursor_before_line
	if not line:match("^:PaletteGenerate") then
		return callback({})
	end

	local arg_line = line:gsub("^:PaletteGenerate%s*", "")
	local args = parse_cmd_args(arg_line)
	local ends_with_space = line:sub(-1):match("%s")
	local arg_count = ends_with_space and #args + 1 or #args

	if arg_count <= 1 then
		local input = arg_line:match('"[^"]*$') or arg_line:match("[%w_%s#]+$") or ""
		callback(get_color_items(input, false))
	elseif arg_count == 2 then
		local methods = { "monochromatic", "analogous", "equally" }
		local items = {}
		for _, m in ipairs(methods) do
			table.insert(items, {
				label = m,
				insertText = m,
				kind = require("cmp").lsp.CompletionItemKind.Method,
			})
		end
		callback(items)
	else
		callback({})
	end
end

function M.palette_generate_complete(arg_lead, cmd_line, _)
	local arg_line = cmd_line:gsub("^PaletteGenerate%s*", "")
	local args = parse_cmd_args(arg_line)
	local current_pos = cmd_line:sub(-1):match("%s") and #args + 1 or #args

	if current_pos <= 1 then
		local matches = {}
		for _, c in ipairs(colors) do
			if c.name:lower():find(arg_lead:lower(), 1, true) then
				table.insert(matches, c.name:find(" ") and '"' .. c.name .. '"' or c.name)
			end
		end
		return matches
	elseif current_pos == 2 then
		return vim.tbl_filter(function(m)
			return m:find(arg_lead:lower(), 1, true)
		end, { "monochromatic", "analogous", "equally" })
	end
	return {}
end

function M.parse_args(line)
	return parse_cmd_args(line)
end

function M.setup()
	local cmp = require("cmp")
	cmp.register_source("colors", source)
	cmp.register_source("palette_colors", palette_source.new())
end

return M
