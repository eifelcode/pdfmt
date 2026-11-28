#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_usage_without_arguments_is_a_help_request()
{
    local exit_code=0
    local stdout
    local stderr_file
    stderr_file="$(mktemp)"

    stdout="$(_usage 0 <<TEXT 2>"${stderr_file}"
Usage: pdfmt foo
TEXT
)" || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_same "Usage: pdfmt foo" "${stdout}"
    assert_same "" "$(cat "${stderr_file}")"
    rm -f "${stderr_file}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_usage_with_missing_arguments_is_an_error()
{
    local exit_code=0
    local stdout
    local stderr_file
    stderr_file="$(mktemp)"

    stdout="$(_usage 1 <<TEXT 2>"${stderr_file}"
Usage: pdfmt foo
TEXT
)" || exit_code=$?

    assert_same "1" "${exit_code}"
    assert_same "" "${stdout}"
    assert_same "ERROR: Missing arguments"$'\n'"Usage: pdfmt foo" "$(cat "${stderr_file}")"
    rm -f "${stderr_file}"
}
