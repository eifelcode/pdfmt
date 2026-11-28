function command_merge_all()
{
    if (( $# < 3 )); then
        _usage $# <<TEXT
Combine PDFs into a single document

Usage:
  pdfmt merge all <input file 1> <input file 2> [input file ...] <output file>

Examples:
  pdfmt merge all cover.pdf toc.pdf chapter1.pdf chapter2.pdf output.pdf

TEXT
        return $?
    fi

    # Load
    # -----------------------------------------------------------------------------------------------------------------
    local -r args=("$@")
    local -r output_file="${args[-1]}"
    local -r input_files=("${args[@]:0:${#args[@]}-1}")



    # Validate
    # -----------------------------------------------------------------------------------------------------------------
    for input_file in "${input_files[@]}"; do
        _assert_is_file "$input_file" || return $?
    done
    _assert_is_not_file "${output_file}" || return $?


    # Handle
    # -----------------------------------------------------------------------------------------------------------------
    local -a assemble_args=()
    for input_file in "${input_files[@]}"; do
        assemble_args+=("${input_file}" "1-z")
    done

    _pdf_assemble "${output_file}" "${assemble_args[@]}"
}
