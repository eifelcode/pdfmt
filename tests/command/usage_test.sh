#!/usr/bin/env bash

# Every command: <function>:<number of required arguments>
# (for scan, the command name itself is the first argument and counts as one)
COMMANDS=(
    command_annotation_list:1
    command_annotation_remove:3
    command_annotation_show:1
    command_extract_even:2
    command_extract_odd:2
    command_extract_range:3
    command_merge_all:3
    command_merge_duplex:3
    command_merge_insert:4
    command_ocr_add:2
    command_ocr_exists:1
    command_ocr_show:1
    command_remove_even:2
    command_remove_odd:2
    command_remove_range:3
    command_sort_duplex:2
    command_sort_move:4
    command_sort_random:2
    command_sort_reverse:2
    command_sort_swap:4
    command_split_all:1
    command_split_length:2
    command_split_range:2
    command_stamp_text:3
    command_workflow_info:1
    command_workflow_run:1
)

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    local file
    for file in "${ROOT_DIR}"/sources/command/*/*.sh; do
        # shellcheck disable=SC1090
        source "${file}"
    done

    export TEST_DIR="/tmp/bashunit_test_$$"
    mkdir -p "${TEST_DIR}"
    cd "${TEST_DIR}" || exit 1
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_DIR}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_commands_without_arguments_show_help()
{
    local entry function_name exit_code stdout stderr_file
    stderr_file="${TEST_DIR}/stderr"

    for entry in "${COMMANDS[@]}"; do
        function_name="${entry%%:*}"

        exit_code=0
        stdout="$("${function_name}" 2>"${stderr_file}")" || exit_code=$?

        assert_same "0" "${exit_code}" "${function_name}: exit code"
        assert_contains "Usage:" "${stdout}"
        assert_same "" "$(cat "${stderr_file}")" "${function_name}: stderr"
    done
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_commands_with_missing_arguments_fail()
{
    local entry function_name required given exit_code stdout stderr_file
    local -a args
    stderr_file="${TEST_DIR}/stderr"

    for entry in "${COMMANDS[@]}"; do
        function_name="${entry%%:*}"
        required="${entry##*:}"

        for (( given=1; given<required; given++ )); do
            args=()
            for (( i=0; i<given; i++ )); do args+=("x"); done

            exit_code=0
            stdout="$("${function_name}" "${args[@]}" 2>"${stderr_file}")" || exit_code=$?

            assert_same "1" "${exit_code}" "${function_name} with ${given} argument(s): exit code"
            assert_same "" "${stdout}" "${function_name} with ${given} argument(s): stdout"
            assert_contains "ERROR: Missing arguments" "$(cat "${stderr_file}")"
            assert_contains "Usage:" "$(cat "${stderr_file}")"
        done
    done
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_scan_commands_missing_output_file()
{
    local exit_code=0
    local stdout

    # only the command name was given: help request
    stdout="$(command_scan_adf adf 2>/dev/null)" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "Usage:" "${stdout}"

    exit_code=0
    stdout="$(command_scan_flatbed flatbed 2>/dev/null)" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "Usage:" "${stdout}"
}
