#!/bin/bash
# Convert colors.lua to JS array for the web interface

lua_file="lua/llawn/colors/colors.lua"
js_file="lua/llawn/colors/palette_generator.js"

# Extract the colors array from Lua and convert to JS
sed -n '/local colors = {/,/}/p' "$lua_file" | \
sed 's/local colors = {/const colorDatabase = [/; s/}$/];/' | \
sed 's/0x/0x/g' | \
sed 's/"\([^"]*\)"/"\1"/g' > temp_colors.js

# Replace the old array in the JS file
# Find the line with // Colors from your colors.lua database
# And replace until the ]; 

# Use sed to replace the block
start_marker="// Colors from your colors.lua database"
end_marker="];"

# Get the content before start
head -n "$(grep -n "$start_marker" "$js_file" | cut -d: -f1)" "$js_file" > temp_js

# Add the new array
echo "$start_marker" >> temp_js
cat temp_colors.js >> temp_js

# Add the rest after ];
tail -n +$(($(grep -n "$end_marker" "$js_file" | cut -d: -f1) + 1)) "$js_file" >> temp_js

# Replace the file
mv temp_js "$js_file"

# Clean up
rm temp_colors.js

echo "Updated palette_generator.js with colors from colors.lua"