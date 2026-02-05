# colors.nvim

[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua)](https://www.lua.org/)
[![Neovim](https://img.shields.io/badge/Neovim-green.svg?style=for-the-badge&logo=neovim)](https://neovim.io/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/llawn/colors.nvim?style=for-the-badge&logo=github)](https://github.com/llawn/colors.nvim)

A Neovim plugin for color management, palette generation, and color highlighting.
Generate color palettes from 500+ predefined colors, manage palettes, and highlight colors in your code with ease.

## Features

- 🎨 **Color Palette Generation**: Generate palettes from 500+ predefined colors using various methods
- 📋 **Palette Management**: Save, load, rename, delete, and export palettes
- 🌈 **Color Highlighting**: Highlight colors in your buffers with a name hint
- 🔍 **Color Pickers**: Both telescope and grid-based color selection interfaces
- 📊 **Palette Statistics**: Get insights about your saved palettes
- 🎯 **Intelligent Interface**: Easy-to-use floating windows with keyboard shortcuts
- ♿ **Accessibility Analysis**: WCAG compliance checking for color contrast
- 💾 **Persistent Storage**: Palettes saved to file for future sessions
- 💡 **Completion**: Easy integration with [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) plugin.

## Integrations & Compatibility

| Integration | Status | Description |
|-------------|--------|-------------|
| ![nvim-cmp](https://img.shields.io/badge/nvim--cmp-✓%20Supported-green?style=flat) | ✅ Supported | Color name completion |
| ![Telescope](https://img.shields.io/badge/Telescope-✓%20Supported-green?style=flat) | ✅ Supported | Fuzzy color picker |

## Installation

[![lazy.nvim](https://img.shields.io/badge/lazy.nvim-Plugin%20Manager-blue?style=flat&logo=neovim)](https://github.com/folke/lazy.nvim)
[![vim.pack](https://img.shields.io/badge/vim.pack-Native%20Package%20Manager-green?style=flat)](https://neovim.io/doc/user/packages.html)

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "llawn/colors.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional, for telescope picker
  },
  config = function()
    require("colors").setup({
      -- your configuration here
    })
  end
}
```

### Using [vim.pack](https://neovim.io/doc/user/packages.html) (Neovim 0.12+)

```lua
local gh = function(x) return 'https://github.com/' .. x end

vim.pack.add(gh('llawn/colors.nvim'))
vim.pack.add(gh('nvim-telescope/telescope.nvim')) -- optional, for telescope picker

require("colors").setup({
  -- your configuration here
})
```

## Configuration

### Default Configuration

```lua
{
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
    palette_list = "<leader>cl",
    palette_stats = "<leader>cs",
    hex_colors = "<leader>cc",
    grid_picker = "<leader>cC",
  },

  -- Autocommand settings
  autocmds = {
    events = { "BufEnter", "BufRead", "TextChanged", "TextChangedI" },
    pattern = "*",
  },
}
```

### Custom Configuration Example

```lua
require("colors").setup({
  highlighting = {
    enabled = true,
    max_lines = 3000,
    enable_virtual_text = false,
  },
  keymaps = {
    toggle_highlight = "<leader>th",
    palette_list = "<leader>pl",
    hex_colors = "<leader>hc",
  }
})
```

Or see [Example](examples/colors.lua) for colors.nvim

### Configuration Options

#### Highlighting Settings

- `enabled` (boolean): Enable/disable color highlighting
- `max_lines` (number): Maximum lines to process per buffer (performance)
- `enable_virtual_text` (boolean): Show color name hints
- `enable_background_highlights` (boolean): Apply background colors

#### Key Mappings

- `toggle_highlight` (string): Toggle color highlighting
- `palette_list` (string): Open palette list
- `palette_stats` (string): Show palette statistics
- `hex_colors` (string): Open telescope color picker
- `grid_picker` (string): Open grid color picker

#### Palette Settings

- `file_path` (string): Path to palette storage file

#### Autocommand Settings

- `events` (table): Events that trigger highlighting
- `pattern` (string): File pattern for autocommands

## Usage

### User Commands

| Command | Description |
|---------|-------------|
| `:PaletteGenerate [color] [method] [count]` | Generate and display a color palette |
| `:PaletteList` | List and manage saved palettes |
| `:PaletteStats` | Show palette collection statistics |
| `:ColorToggle` | Toggle hex color highlighting |
| `:HexColors` | Open telescope color picker |
| `:ColorPick2D` | Open 2D grid color picker |

### Palette Generation

<img width="626" height="318" alt="Image" src="https://github.com/user-attachments/assets/54629ce6-8ffe-492e-9479-887d4cae8bef" />

```vim
:PaletteGenerate red monochromatic 5
:PaletteGenerate blue equally 4
:PaletteGenerate purple analogous 8
:PaletteGenerate "carbon black" monochromatic 5
:PaletteGenerate "electric blue" analogous 6
```

- **Monochromatic**: Variations of a single color (variation of hue)
- **Analogous**: Colors adjacent on the color wheel (variation of lightness)
- **Equally**: Colors evenly spaced on the color wheel (variation of hue)

Color names with spaces must be enclosed in quotes

#### Palette List Management

<img width="621" height="372" alt="Image" src="https://github.com/user-attachments/assets/c2f5ef5c-5136-4bb9-b252-4d2fce9cc976" />

- Open palette list: `<leader>cl` or `:PaletteList`
- In palette list:
  - `l` - Load selected palette
  - `e` - Export palette to clipboard (Lua Format)
  - `r` - Rename palette
  - `d` - Delete palette
  - `q` - Close list

#### Palette View Controls

<img width="626" height="443" alt="Image" src="https://github.com/user-attachments/assets/ad31787a-389e-4b83-b171-ae3dbf8ad39d" />

When viewing a palette:

- `l` - Back to palette list
- `e` - Export palette to clipboard (Lua format)
- `d` - Delete current palette
- `r` - Rename current palette
- `a` - Check accessibility (WCAG compliance)
- `q` - Quit menu

### Color Highlighting

![Highlight](https://github.com/user-attachments/assets/6c21fd77-db11-4447-8428-12e1fea151d6)

#### Toggle Highlighting

```vim
:ColorToggle
" or with keymap: <leader>ct
```

#### Refresh Highlighting

```vim
:lua require("colors.api").refresh_highlight()
```

### Color Pickers

#### Telescope Color Picker

<img width="1551" height="891" alt="TelescopeColorPicker" src="https://github.com/user-attachments/assets/29249eb5-0001-4315-9dc6-ed62634bb162" />

```vim
:HexColors
" or with keymap: <leader>cc
```

#### Grid Color Picker

<img width="1551" height="891" alt="GridColorPicker" src="https://github.com/user-attachments/assets/1c3227ba-42be-4d71-8775-ae6b14ff4912" />

```vim
:ColorPick2D
" or with keymap: <leader>cC
```

### Palette Statistics

```vim
:PaletteStats
" or with keymap: <leader>cs
```

## nvim-cmp Integration

colors.nvim provides an nvim-cmp source for color name completion with documentation and hex values.

### Setup

Add the colors source to your nvim-cmp configuration:

```lua
-- Add in your nvim-cmp config
require("colors.cmp_colors").setup()

cmp.setup({
  sources = cmp.config.sources({
    { name = "colors" },
  }),
  formatting = {
    format = function(entry, vim_item)
      vim_item = cmp_colors.format(entry, vim_item)
      return vim_item
    end,
  },
})

cmp.setup.cmdline(":", {
  sources = cmp.config.sources({
    { name = "palette_colors" },
  }),
})
```

See [Example](examples/nvim-cmp.lua) for a complete examples.

## Palette Storage

Palettes are stored in Lua format at `vim.fn.stdpath("data") .. "/palettes.lua"` by default. Each palette includes:

```lua
{
  colors = { 0xFF0000, 0x00FF00, 0x0000FF, ... }, -- Color values
  metadata = {
    method = "complementary",
    base_color = "red",
    options = {},
    created_at = "2026-01-01 12:00:00",
    color_count = 5
  }
}
```

## License

[![MIT License](https://img.shields.io/badge/License-MIT-yellow?style=flat)](LICENSE)

---

## Show Your Support

[![Made with Lua](https://img.shields.io/badge/Made%20with%20Lua-blue?style=flat&logo=lua)](https://www.lua.org/)
[![Neovim Plugin](https://img.shields.io/badge/Neovim%20Plugin-green?style=flat&logo=neovim)](https://neovim.io/)
[![GitHub](https://img.shields.io/badge/GitHub-View%20on%20GitHub-black?style=flat&logo=github)](https://github.com/llawn/colors.nvim)

If you find this plugin helpful, consider giving it a ⭐ on GitHub!
