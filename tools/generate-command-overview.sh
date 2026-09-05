#!/usr/bin/env bash
# =====================================================================================================================
# Script: generate-command-overview.sh
#
# Description:
# This script scans the 'sources/command/' directory of the pdfmt project and automatically generates a Markdown
# table of all available commands. The command descriptions are extracted dynamically from the respective script
# files (it reads the first line of text after the 'cat <<' heredoc block).
# Internal scripts (starting with '_') as well as 'main.sh' are automatically ignored.
#
# Usage:
# The script outputs the generated Markdown table to standard output (stdout).
# 1. Run the script and copy the output to your clipboard:
#    ./tools/generate-command-overview.sh
# 2. Or redirect the output directly into a temporary file:
#    ./tools/generate-command-overview.sh > temp_table.md
#
# The generated text can then easily be pasted into your README.md.
# =====================================================================================================================

readonly COMMAND_DIR="sources/command"

function extract_description() {
    local -r file="$1"
    awk '/cat[ \t]+<<[A-Za-z0-9_-]+/ {
        while ((getline line) > 0) {
            if (line ~ /^[ \t]*$/) continue; # Skip empty lines
            sub(/^[ \t]+/, "", line);        # Remove leading spaces
            sub(/[ \t]+$/, "", line);        # Remove trailing spaces
            print line;
            exit;
        }
    }' "$file"
}

echo "### Command Overview"
echo ""
echo "Below is a quick overview of all available commands. To get detailed usage instructions for a specific command, simply run \`pdfmt <command> help\`."
echo ""
echo "| Category | Command | Description |"
echo "| :--- | :--- | :--- |"

# all categories
for category_path in "$COMMAND_DIR"/*/; do
    [[ -d "$category_path" ]] || continue

    category=$(basename "$category_path")
    category_capitalized="$(tr '[:lower:]' '[:upper:]' <<< ${category:0:1})${category:1}"

    first_in_category=true
    for script_file in "$category_path"/*.sh; do
        [[ -f "$script_file" ]] || continue

        command_name=$(basename "$script_file" .sh)
        if [[ "$command_name" == _* || "$command_name" == "main" ]]; then
            continue
        fi

        desc=$(extract_description "$script_file")
        if [[ $command_name == "help" ]]; then
            desc="Help of category *$category_capitalized*"
        fi

        if [[ -z "$desc" ]]; then
            desc="No description available"
        fi

        if $first_in_category; then
            cat_cell="**${category_capitalized}**"
            first_in_category=false
        else
            cat_cell=""
        fi

        echo "| $cat_cell | \`${category} ${command_name}\` | $desc |"
    done
done

# Category: Misc
echo "| **Misc** | \`help\` | Help of \`pdfmt\` |"
echo "|  | \`version\` | Displays the version of \`pdfmt\` |"
