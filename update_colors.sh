#!/bin/bash
# Convert colors.lua to JS array for the web interface

lua_file="lua/llawn/colors/colors.lua"
js_file="lua/llawn/colors/palette_generator.js"

# Extract the colors array from Lua and convert to JS
sed -n '/^local colors = {/,/^}/p' "$lua_file" | \
sed '1s/local colors = {/const colorDatabase = [/; $s/^  }$/];/' | \
sed 's/=0x/:0x/g; s/name=/name:/g; s/color=/color:/g' > temp_colors.js

# Replace the array in the JS file using awk
awk -v colors_file="temp_colors.js" '
BEGIN {
    in_array = 0
    printed_colors = 0
}
{
    if ($0 ~ /\/\/ Colors from your colors.lua database/ && !printed_colors) {
        print $0
        while ((getline line < colors_file) > 0) {
            print line
        }
        printed_colors = 1
        in_array = 1
    } else if (in_array && ($0 ~ /\];/ || $0 ~ /^  }/)) {
        in_array = 0
    } else if (!in_array) {
        print $0
    }
}
' "$js_file" > temp_js

# Replace the file
mv temp_js "$js_file"

# Clean up
rm temp_colors.js

echo "Updated palette_generator.js with colors from colors.lua"