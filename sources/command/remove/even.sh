function command_remove_even()
{
    if (( $# < 2 )); then
        _usage $# <<TEXT
Remove all even-numbered pages

Usage:
  pdfmt remove even <input file> <output file>

Examples:
  pdfmt remove even input.pdf output.pdf

TEXT
        return $?
    fi


    # Load
    # -----------------------------------------------------------------------------------------------------------------
    local -r input_file="${1:-}"
    local -r output_file="${2:-}"


    # Validate
    # -----------------------------------------------------------------------------------------------------------------
    _assert_is_file "${input_file}" || return $?
    _assert_is_not_file "${output_file}" || return $?


    # Handle
    # -----------------------------------------------------------------------------------------------------------------
    local -r num_pages="$(_pdf_get_num_pages "${input_file}")"
    local -r keep_pages=$(seq 1 2 "${num_pages}" | tr '\n' ' ')

    read -ra pages_array <<< "$keep_pages"
    _pdf_select_pages "${input_file}" "${output_file}" "${pages_array[@]}"
}
