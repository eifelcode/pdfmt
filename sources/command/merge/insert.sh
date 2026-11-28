function command_merge_insert()
{
    if (( $# < 4 )); then
        _usage $# <<TEXT
Insert a PDF into another document at a specific page

Usage:
  pdfmt merge insert <input file> <position> <insert file> <output file>

Examples:
  pdfmt merge insert book.pdf 2 toc.pdf output.pdf

TEXT
        return $?
    fi

    # Load
    # -----------------------------------------------------------------------------------------------------------------
    local -r input_file="${1:-}"
    local -r position="${2:-}"
    local -r insert_file="${3:-}"
    local -r output_file="${4:-}"


    # Validate
    # -----------------------------------------------------------------------------------------------------------------
    _assert_is_file "${input_file}" || return $?
    _assert_is_digit "${position}" || return $?
    _assert_is_file "${insert_file}" || return $?
    _assert_is_not_file "${output_file}" || return $?


    # Handle
    # -----------------------------------------------------------------------------------------------------------------
    local -r num_pages="$(_pdf_get_num_pages "${input_file}")"

    # The inserted file goes in front of the given page; position 1 or less means in front of the first page, a position
    # behind the last page appends the file.
    local -a assemble_args=()
    if (( position <= 1 )); then
        assemble_args=("${insert_file}" "1-z" "${input_file}" "1-z")
    elif (( position > num_pages )); then
        assemble_args=("${input_file}" "1-z" "${insert_file}" "1-z")
    else
        assemble_args=(
            "${input_file}" "1-$((position - 1))"
            "${insert_file}" "1-z"
            "${input_file}" "${position}-z"
        )
    fi

    _pdf_assemble "${output_file}" "${assemble_args[@]}"
}
