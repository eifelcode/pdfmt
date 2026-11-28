function command_sort_duplex()
{
    if (( $# < 2 )); then
        _usage $# <<TEXT
Reorder a single PDF containing consecutive front and back scans

Usage:
  pdfmt sort duplex <input file> <output file>

Examples:
  pdfmt sort duplex input.pdf output.pdf

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
    if (( num_pages % 2 != 0 )); then
        _log_error "Odd number of pages. Total pages: $num_pages"
        return 1
    fi

    # Halve the number of pages
    local -r half=$((num_pages / 2))

    # First half: Front pages (1 to half)
    # Second half: Back pages (half+1 to pages), scanned upside down and therefore in reverse order
    _pdf_assemble --collate "${output_file}" \
        "${input_file}" "1-${half}" \
        "${input_file}" "${num_pages}-$((half + 1))"
}
