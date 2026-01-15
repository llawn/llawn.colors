--- Test the palette generator functionality

local palette_gen = require('llawn.colors.palette_generator')
local palette_mgr = require('llawn.colors.palette_manager')

-- Test basic functionality
print("=== Color Palette Generator Tests ===\n")

-- Test color name retrieval
print("Available colors (first 10):")
local names = palette_gen.get_color_names()
for i = 1, math.min(10, #names) do
    print(string.format("  %d. %s", i, names[i]))
end
print()

-- Test getting a specific color
local red_color = palette_gen.get_color_by_name("red")
if red_color then
    print("Red color:", red_color.name, string.format("0x%06x", red_color.color))
else
    print("Red color not found")
end
print()

-- Test palette generation
print("=== Palette Generation Tests ===\n")

local test_base = "red"
local test_count = 5

print("Monochromatic palette from '" .. test_base .. "' (" .. test_count .. " colors):")
local mono_palette = palette_gen.generate_palette(test_base, "monochromatic", test_count)
if mono_palette then
    for i, color in ipairs(mono_palette) do
        print(string.format("  %d. %s (#%06X)", i, color.name, color.color))
    end
else
    print("  Failed to generate palette")
end
print()

print("Analogous palette from '" .. test_base .. "' (" .. test_count .. " colors):")
local analog_palette = palette_gen.generate_palette(test_base, "analogous", test_count)
if analog_palette then
    for i, color in ipairs(analog_palette) do
        print(string.format("  %d. %s (#%06X)", i, color.name, color.color))
    end
else
    print("  Failed to generate palette")
end
print()

print("Complementary palette from '" .. test_base .. "' (" .. test_count .. " colors):")
local comp_palette = palette_gen.generate_palette(test_base, "complementary", test_count)
if comp_palette then
    for i, color in ipairs(comp_palette) do
        print(string.format("  %d. %s (#%06X)", i, color.name, color.color))
    end
else
    print("  Failed to generate palette")
end
print()

print("Triadic palette from '" .. test_base .. "' (" .. test_count .. " colors):")
local tri_palette = palette_gen.generate_palette(test_base, "triadic", test_count)
if tri_palette then
    for i, color in ipairs(tri_palette) do
        print(string.format("  %d. %s (#%06X)", i, color.name, color.color))
    end
else
    print("  Failed to generate palette")
end

-- Test new generation methods
print("\n=== Testing New Generation Methods ===")

print("Tetradic palette from 'blue':")
local tetradic_palette = palette_gen.generate_palette("blue", "tetradic", 4)
if tetradic_palette then
    for i, color in ipairs(tetradic_palette) do
        print(string.format("  %d. %s (#%06X)", i, color.name, color.color))
    end
else
    print("  Failed to generate palette")
end

print("\nSplit complementary palette from 'green':")
local split_comp_palette = palette_gen.generate_palette("green", "split_complementary", 3)
if split_comp_palette then
    for i, color in ipairs(split_comp_palette) do
        print(string.format("  %d. %s (#%06X)", i, color.name, color.color))
    end
else
    print("  Failed to generate palette")
end

-- Test accessibility checking
print("\n=== Testing Accessibility Analysis ===")
local test_palette = palette_gen.generate_palette("red", "complementary", 3)
if test_palette then
    local analysis = palette_gen.analyze_palette_accessibility(test_palette)
    print("Accessibility Analysis:")
    print(string.format("  AA Normal: %d/%d passed (%.1f%%)",
        analysis.compliance.aa_normal.passed, analysis.compliance.aa_normal.total,
        analysis.compliance.aa_normal.passed/analysis.compliance.aa_normal.total*100))
    print(string.format("  AAA Normal: %d/%d passed (%.1f%%)",
        analysis.compliance.aaa_normal.passed, analysis.compliance.aaa_normal.total,
        analysis.compliance.aaa_normal.passed/analysis.compliance.aaa_normal.total*100))

    if #analysis.recommendations > 0 then
        print("  Recommendations:")
        for _, rec in ipairs(analysis.recommendations) do
            print("    - " .. rec)
        end
    end
end

-- Test palette management
print("\n=== Testing Palette Management ===")
local test_palette = palette_gen.generate_palette("purple", "triadic", 3)
if test_palette then
    local success, err = palette_mgr.save_palette(test_palette, "test_triadic", "triadic", "purple")
    if success then
        print("Successfully saved palette 'test_triadic'")

        local loaded = palette_mgr.load_palette("test_triadic")
        if loaded then
            print("Successfully loaded palette with " .. #loaded.colors .. " colors")
        end

        local deleted = palette_mgr.delete_palette("test_triadic")
        if deleted then
            print("Successfully deleted palette")
        end
    else
        print("Failed to save palette: " .. err)
    end
end

-- Test statistics
local stats = palette_mgr.get_palette_stats()
print("\nPalette Statistics:")
print("  Total palettes: " .. stats.total_palettes)
print("  Total colors: " .. stats.total_colors)
print("  Average palette size: " .. string.format("%.1f", stats.average_palette_size))

print("\n=== Test Complete ===")