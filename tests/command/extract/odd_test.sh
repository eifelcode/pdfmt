#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/extract/odd.sh"

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
function test_command_extract_odd()
{
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    command_extract_odd "${ROOT_DIR}/tests/_data/pages.pdf" output.pdf

    assert_same "output.pdf" "$(printf '%s\n' *)"

    assert_same "1357" "$(pdftotext output.pdf - | tr -d '[:space:]')"
}
