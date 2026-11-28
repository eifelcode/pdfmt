#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/common/pdf.sh"

    export TEST_DIR="/tmp/bashunit_test_$$"
    mkdir -p "${TEST_DIR}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_DIR:-/nonexistent}"
}

# Prints the text of every page (the fixtures contain the page number as text) in one line, e.g. "3 1 5".
function page_texts()
{
    local -r file="${1}"
    local -r num_pages="$(_pdf_get_num_pages "${file}")"

    local texts=""
    for (( i=1; i<=num_pages; i++ )); do
        texts+="$(pdftotext -f "${i}" -l "${i}" "${file}" - | tr -d '[:space:]') "
    done

    echo "${texts% }"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_get_num_pages()
{
    local exit_code=0
    local result

    result=$(_pdf_get_num_pages "${ROOT_DIR}/tests/_data/pages.pdf") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "8" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_get_num_pages_file_not_found()
{
    local exit_code=0

    _pdf_get_num_pages "${ROOT_DIR}/tests/_data/unknown-file.pdf" >/dev/null 2>&1 || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_single_page()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "5") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "5" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_page_range()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "1-3") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "1 2 3" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_multiple_pages()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "1,3,5") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "1 3 5" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_multiple_ranges()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "1-3,5-7") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "1 2 3 5 6 7" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_mixed_pages_and_ranges()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "1-3,5,8-10") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "1 2 3 5 8 9 10" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_max_pages()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "3-5" "5") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "3 4 5" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_page_exceeds_max_pages()
{
    local exit_code=0

    _pdf_parse_ranges "6" "5" >/dev/null 2>&1 || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_range_exceeds_max_pages()
{
    local exit_code=0

    _pdf_parse_ranges "3-6" "5" >/dev/null 2>&1 || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_invalid_range_order()
{
    local exit_code=0

    _pdf_parse_ranges "3-1" >/dev/null 2>&1 || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_invalid_range()
{
    local exit_code=0

    _pdf_parse_ranges "invalid" >/dev/null 2>&1 || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_zero_page()
{
    local exit_code=0

    _pdf_parse_ranges "0" >/dev/null 2>&1 || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_parse_ranges_with_spaces()
{
    local exit_code=0
    local result

    result=$(_pdf_parse_ranges "1-3, 5, 8-10") || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "1 2 3 5 8 9 10" "${result}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_select_pages()
{
    local exit_code=0
    local -r input="${ROOT_DIR}/tests/_data/pages.pdf"
    local -r output="${TEST_DIR}/out.pdf"

    # order and duplicates are kept
    _pdf_select_pages "${input}" "${output}" 3 1 1 5 || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "3 1 1 5" "$(page_texts "${output}")"
    rm -f "${output}"

    # ranges
    _pdf_select_pages "${input}" "${output}" "2-4,8" || exit_code=$?
    assert_same "2 3 4 8" "$(page_texts "${output}")"
    rm -f "${output}"

    # reverse (z is the last page)
    _pdf_select_pages "${input}" "${output}" "z-1" || exit_code=$?
    assert_same "8 7 6 5 4 3 2 1" "$(page_texts "${output}")"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_select_pages_failure()
{
    local exit_code=0

    _pdf_select_pages "${ROOT_DIR}/tests/_data/pages.pdf" "${TEST_DIR}/out.pdf" 99 >/dev/null 2>&1 || exit_code=$?

    assert_not_same "0" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_assemble()
{
    local exit_code=0
    local -r pages="${ROOT_DIR}/tests/_data/pages.pdf"
    local -r output="${TEST_DIR}/out.pdf"

    # several files and ranges in the given order
    _pdf_assemble "${output}" "${pages}" "1-2" "${pages}" "7-z" "${pages}" "4" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "1 2 7 8 4" "$(page_texts "${output}")"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_assemble_collate()
{
    local exit_code=0
    local -r pages="${ROOT_DIR}/tests/_data/pages.pdf"
    local -r output="${TEST_DIR}/out.pdf"

    # interleaved: first of range 1, first of range 2, second of range 1, ...
    _pdf_assemble --collate "${output}" "${pages}" "1-3" "${pages}" "8-6" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "1 8 2 7 3 6" "$(page_texts "${output}")"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_pdf_overlay()
{
    local exit_code=0
    local -r input="${ROOT_DIR}/tests/_data/pages.pdf"
    local -r output="${TEST_DIR}/out.pdf"

    # the first page of the overlay file is laid on every page
    _pdf_overlay "${input}" "${ROOT_DIR}/tests/_data/duplex-frontside.pdf" "${output}" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "8" "$(_pdf_get_num_pages "${output}")"
    assert_contains "1" "$(pdftotext -f 8 -l 8 "${output}" -)"
    assert_contains "8" "$(pdftotext -f 8 -l 8 "${output}" -)"
}
