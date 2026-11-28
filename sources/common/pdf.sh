#######################################################################################################################
# Determines and prints the total number of pages of a given PDF file.
#
# Usage:
#   _pdf_get_num_pages "test.pdf"
#
# Arguments:
#   $1: Input file
# Outputs:
#   - Outputs a message to STDERR if the total number of pages can not be determined
#   - The number of pages
# Returns:
#   0 on success, 1 on failure
#######################################################################################################################
function _pdf_get_num_pages()
{
    local -r input_file="${1}"

    _assert_is_file "${input_file}" "Unable to determine the total number of pages" || return 1

    # qpdf exits with 3 if the PDF has warnings only; the number of pages is printed anyway
    local num_pages
    num_pages="$(qpdf --show-npages "${input_file}" 2>/dev/null)" || true

    _assert_is_digit "${num_pages}" "Unable to determine the total number of pages" || return $?

    echo "$num_pages"
}

#######################################################################################################################
# Creates a new PDF from page ranges of one or more PDF files, in the given order.
#
# Usage:
#   _pdf_assemble "out.pdf" "a.pdf" "1-3,7" "b.pdf" "z-1"
#   _pdf_assemble --collate "out.pdf" "front.pdf" "1-z" "back.pdf" "z-1"
#
# Page ranges are qpdf page ranges: "1-3,7" selects pages, "z" is the last page, "z-1" reverses all pages. A page
# can be selected several times. With --collate pages of the ranges are interleaved: first page of the first range,
# first page of the second range, second page of the first range, ...
#
# Arguments:
#   $1: (optional) --collate
#   $1: Output file
#   $@: Pairs of input file and page range
# Returns:
#   0 on success, otherwise the exit code of qpdf
#######################################################################################################################
function _pdf_assemble()
{
    local -a options=()
    if [[ "${1:-}" == "--collate" ]]; then
        options+=(--collate)
        shift
    fi

    local -r output_file="${1}"
    shift

    # (the expansion of an empty array is an error with "set -u" in Bash < 4.4)
    _qpdf_run --empty ${options[@]+"${options[@]}"} --pages "$@" -- "${output_file}"
}

#######################################################################################################################
# Creates a new PDF with the given pages of a PDF file, in the given order.
#
# Usage:
#   _pdf_select_pages "in.pdf" "out.pdf" 3 1 5 6
#   _pdf_select_pages "in.pdf" "out.pdf" "1-4,8" "z"
#
# Arguments:
#   $1: Input file
#   $2: Output file
#   $@: Page numbers or qpdf page ranges
# Returns:
#   0 on success, otherwise the exit code of qpdf
#######################################################################################################################
function _pdf_select_pages()
{
    local -r input_file="${1}"
    local -r output_file="${2}"
    shift 2

    local pages
    pages="$(IFS=,; echo "$*")"

    _pdf_assemble "${output_file}" "${input_file}" "${pages}"
}

#######################################################################################################################
# Lays the first page of an overlay PDF on top of every page of a PDF file (stamp).
#
# Usage:
#   _pdf_overlay "in.pdf" "stamp.pdf" "out.pdf"
#
# Arguments:
#   $1: Input file
#   $2: PDF whose first page is used as overlay
#   $3: Output file
# Returns:
#   0 on success, otherwise the exit code of qpdf
#######################################################################################################################
function _pdf_overlay()
{
    _qpdf_run "${1}" --overlay "${2}" --from=1 --repeat=1 -- "${3}"
}

#######################################################################################################################
# Parse a comma-separated range string (e.g., "1-3,5,8-10") into individual pages.
#
# Usage:
#
# Arguments:
#   $1 - The range string (e.g., "1-3,5")
#   $2 - (Optional) Max pages of the PDF to validate against bounds
# Outputs:
#   - Prints a space-separated list of valid pages
# Returns:
#   0 if successful, 1 if parsing fails or bounds are exceeded
#######################################################################################################################
function _pdf_parse_ranges()
{
    local range_string="${1:-}"
    local max_pages="${2:-}"

    local -a parsed_pages=()

    if [[ -z "$range_string" ]]; then
        _log_error "Range is empty."
        return 1
    fi

    # Split string into an array based on commas
    local -a parts
    IFS=',' read -ra parts <<< "$range_string"

    for part in "${parts[@]}"; do
        # remove white spaces (if user enters: "1-3, 5")
        part="${part// /}"

        if [[ "$part" =~ ^([1-9][0-9]*)-([1-9][0-9]*)$ ]]; then
            # case: range like 1-3
            local start="${BASH_REMATCH[1]}"
            local end="${BASH_REMATCH[2]}"

            if (( start > end )); then
                _log_error "Invalid range '$part' (start > end)."
                return 1
            fi

            if [[ -n "$max_pages" ]] && (( end > max_pages )); then
                _log_error "Range '$part' exceeds total pages ($max_pages)."
                return 1
            fi

            if (( end - start > 1000 )); then
                _log_error "Page range too large. Max page range is 1000."
                return 1
            fi

            for (( i=start; i<=end; i++ )); do
                parsed_pages+=("$i")
            done

        elif [[ "$part" =~ ^[1-9][0-9]*$ ]]; then
            # case: single page
            if [[ -n "$max_pages" ]] && (( part > max_pages )); then
                _log_error "Page '$part' exceeds total pages ($max_pages)."
                return 1
            fi
            parsed_pages+=("$part")

        else
            # case: invalid format
            _log_error "Error: Invalid format in range part '$part'."
            return 1
        fi
    done

    echo "${parsed_pages[@]}"
}
