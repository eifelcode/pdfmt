#######################################################################################################################
# Creates a secure temporary file with an optional file extension suffix.
#
# Works cross-platform on macOS (BSD) and Linux (GNU) without coreutils dependencies.
#
# Usage:
#   file="$(_create_temp_file)"         # Output: /tmp/tmp.XXXXXX
#   file="$(_create_temp_file .pdf)"    # Output: /tmp/tmp.XXXXXX.pdf
#
# Arguments:
#   $1: (optional) Suffix/extension to append to the temporary file
#
# Outputs:
#   Prints the absolute path of the created temporary file to STDOUT
#
# Returns:
#   0 on success, 1 on failure
#######################################################################################################################
function _create_temp_file()
{
    local -r suffix="${1:-}"
    local tmp_file
    tmp_file="$(mktemp)" || return 1

    if [[ -n "${suffix}" ]]; then
        mv "${tmp_file}" "${tmp_file}${suffix}" || return 1
        tmp_file="${tmp_file}${suffix}"
    fi

    echo "${tmp_file}"
}
