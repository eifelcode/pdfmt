#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/annotation/remove.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/annotation/show.sh"

    export TEST_DIR="/tmp/bashunit_test_$$"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR" || exit 1
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "$TEST_DIR"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_help()
{
    local exit_code=0
    local output

    output="$(command_annotation_remove)" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_matches "Remove annotations from a PDF document" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_all()
{
    local exit_code=0
    local output
    local output_file="cleaned.pdf"

    # pre check
    output="$(command_annotation_show "${ROOT_DIR}/tests/_data/annotations.pdf" "all")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "Page 1" "${output}"

    # function check
    command_annotation_remove "${ROOT_DIR}/tests/_data/annotations.pdf" "all" "${output_file}" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "${output_file}" "$(printf '%s\n' *)"

    # post check
    output="$(command_annotation_show "${output_file}" "all")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_not_contains "Page 1" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_specific_type()
{
    local exit_code=0
    local output_file="cleaned_circle.pdf"

    # pre check
    output="$(command_annotation_show "${ROOT_DIR}/tests/_data/annotations.pdf" "all")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "Page 1: Highlight" "${output}"
    assert_contains "Page 1: Underline" "${output}"
    assert_contains "Page 1: StrikeOut" "${output}"
    assert_contains "Page 1: Squiggly" "${output}"

    # function check
    command_annotation_remove "${ROOT_DIR}/tests/_data/annotations.pdf" "underline,strikeout" "${output_file}" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "${output_file}" "$(printf '%s\n' *)"

    # post check
    output="$(command_annotation_show "${output_file}" "all")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "Page 1: Highlight" "${output}"
    assert_not_contains "Page 1: Underline" "${output}"
    assert_not_contains "Page 1: StrikeOut" "${output}"
    assert_contains "Page 1: Squiggly" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_unknown_type()
{
    local exit_code=0
    local output_file="failed.pdf"

    command_annotation_remove "${ROOT_DIR}/tests/_data/annotations.pdf" "nonexistenttype" "${output_file}" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_not_same "${output_file}" "$(printf '%s\n' *)"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_input_file_not_existing()
{
    local exit_code=0
    local output_file="output.pdf"

    command_annotation_remove "${ROOT_DIR}/tests/_data/unknown-file.pdf" "all" "${output_file}" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_not_same "${output_file}" "$(printf '%s\n' *)"
}

# Creates a qpdf wrapper that behaves like the real one, but ends "--update-from-json" with the given exit code.
function create_qpdf_wrapper()
{
    local -r exit_code="${1}"
    local -r message="${2}"
    local -r real_qpdf="$(command -v qpdf)"

    mkdir -p "${TEST_DIR}/bin"
    cat > "${TEST_DIR}/bin/qpdf" <<EOF2
#!/bin/bash
for argument in "\$@"; do
    if [[ "\${argument}" == --update-from-json=* ]]; then
        "${real_qpdf}" "\$@"
        echo "${message}" >&2
        exit ${exit_code}
    fi
done
exec "${real_qpdf}" "\$@"
EOF2
    chmod +x "${TEST_DIR}/bin/qpdf"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_qpdf_warnings_are_no_error()
{
    local exit_code=0
    local output_file="cleaned.pdf"

    # qpdf exit code 3: finished with warnings, output was written
    create_qpdf_wrapper 3 "WARNING: something minor"

    PATH="${TEST_DIR}/bin:${PATH}" command_annotation_remove "${ROOT_DIR}/tests/_data/annotations.pdf" "all" "${output_file}" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_file_exists "${output_file}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_qpdf_error_is_reported()
{
    local exit_code=0
    local output
    local output_file="cleaned.pdf"

    create_qpdf_wrapper 2 "qpdf: something went wrong"

    output="$(PATH="${TEST_DIR}/bin:${PATH}" command_annotation_remove "${ROOT_DIR}/tests/_data/annotations.pdf" "all" "${output_file}" 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_contains "Failed to write output PDF (qpdf exit code 2)" "${output}"
    assert_contains "qpdf: something went wrong" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_annotation_remove_unreadable_mktemp_file()
{
    local exit_code=0
    local output_file="cleaned.pdf"
    local -r real_mktemp="$(command -v mktemp)"

    # mktemp that creates write-only files (qpdf must not depend on the permissions mktemp chooses)
    mkdir -p "${TEST_DIR}/bin"
    cat > "${TEST_DIR}/bin/mktemp" <<EOF2
#!/bin/bash
file="\$("${real_mktemp}" "\$@")" || exit \$?
chmod 200 "\${file}"
echo "\${file}"
EOF2
    chmod +x "${TEST_DIR}/bin/mktemp"

    PATH="${TEST_DIR}/bin:${PATH}" command_annotation_remove "${ROOT_DIR}/tests/_data/annotations.pdf" "all" "${output_file}" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_file_exists "${output_file}"
}
