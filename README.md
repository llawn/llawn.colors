# llawn.colors

Manage colors in Neovim: highlighting, picking, and palette generation.

## Features

- **3 Generation Methods**: Monochromatic, Analogous, Equally
- **Advanced Controls** for palette generation
- **Accessibility**: Real-time WCAG accessibility analysis
- **Telescope Integration**: Browse palettes with telescope (optional)
- **500+ Colors**: Comprehensive color database with named colors

## Installation

Using your favorite plugin manager:

### Lazy.nvim
```lua
{
  'llawn/colors.nvim',
  config = function()
    require('colors').setup()
  end
}
```

## Setup

### Default configuration

```lua
require('llawn.colors').setup()
```

### Advanced configuration

```lua
require('llawn.colors').setup({
  highlighting = {
    enabled = true,
    max_lines = 5000,
    enable_virtual_text = true,
    enable_background_highlights = true,
  },
  
  keymaps = {
    toggle_highlight = "<leader>ct",
  },
})
```

### Integration with nvim-cmp

```lua
-- Add to your nvim-cmp configuration
local cmp = require('cmp')

cmp.setup({
  sources = {
    { name = 'colors' },
  }
})
```

## Usage

### Commands

- `:PaletteGenerate <color> <method> <count>` - Generate a color palette
- `:PaletteList` - Browse saved palettes (requires telescope)
- `:PaletteStats` - View collection statistics

### Examples

```vim
:PaletteGenerate red monochromatic 5
:PaletteGenerate blue equally 4
:PaletteGenerate purple analogous 8
```

### Key Mappings

- `<leader>ct` - Toggle color highlighting (configurable)

### Lua API

```lua
local colors = require('llawn.colors')

-- Generate a palette
local palette = colors.generate_palette('red', 'monochromatic', 5)

-- List all palettes
local palettes = colors.list_palettes()

-- Get statistics
local stats = colors.get_palette_stats()

-- Toggle highlighting manually
require('llawn.colors.colors_highlighter').toggle()

-- Access configuration
local conf = require('llawn.colors.conf')
```

## Configuration Options

### Highlighting Settings

- `enabled` (boolean): Enable/disable color highlighting
- `max_lines` (number): Maximum lines to process per buffer (performance)
- `enable_virtual_text` (boolean): Show color name hints
- `enable_background_highlights` (boolean): Apply background colors

### Key Mappings

- `toggle_highlight` (string): Key mapping to toggle highlighting

## License

MIT License
