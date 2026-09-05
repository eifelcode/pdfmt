#!/usr/bin/env bash
# =====================================================================================================================
# Script: format-code.sh
#
# Description:
# Automatically formats and standardizes shell scripts (*.sh) within the specified target directories.
#
# Operations performed on *.sh files:
# - Ensures a single newline at the end of files
# - Replaces tabs with 4 spaces
# - Normalizes shebangs to '#!/usr/bin/env bash'
# - Removes trailing whitespaces at the end of each line
# - Removes trailing empty lines at the end of files
# - Normalizes comment formatting by ensuring a space after '#'
#
# Usage:
# ./format-code.sh
# =====================================================================================================================

readonly DIRECTORIES=("sources" "tests" "tools")

function main()
{
    for directory in "${DIRECTORIES[@]}"; do
        # ensure newline at the end of file
        find "$directory" -type f -name "*.sh" -exec sed -i -e '$a\' {} +

        # replace tabs with spaces
        find "$directory" -type f -name "*.sh" -exec sed -i 's/\t/    /g' {} +

        # normalize shebang
        find "$directory" -type f -name "*.sh" -exec sed -i '1s|^#!/.*|#!/usr/bin/env bash|' {} +

        # remove trailing whitespace at the end of each line
        find "$directory" -type f -name "*.sh" -exec sed -i 's/[ \t]*$//' {} +

        # remove trailing empty lines at the end of file
        find "$directory" -type f -name "*.sh" -exec sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' {} +

        # add space after comment start "#", but not for shebangs, double hashes, or empty comments
        find "$directory" -type f -name "*.sh" -exec sed -i 's/^\([ \t]*\)#\([^#! ]\)/\1# \2/' {} +
    done
}

main "$@"
