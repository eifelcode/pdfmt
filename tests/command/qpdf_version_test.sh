#!/usr/bin/env bash

# Commands that use qpdf (the groups check the version in their _index.sh, annotation per subcommand).
GROUPS_USING_QPDF=(extract merge remove sort split stamp)

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    local file
    for file in "${ROOT_DIR}"/sources/command/*/*.sh; do
        # shellcheck disable=SC1090
        source "${file}"
    done

    export TEST_DIR="/tmp/bashunit_test_$$"
    mkdir -p "${TEST_DIR}/bin"
    cd "${TEST_DIR}" || exit 1

    # a qpdf older than the supported version
    printf '#!/bin/bash\necho "qpdf version 10.6.3"\n' > "${TEST_DIR}/bin/qpdf"
    chmod +x "${TEST_DIR}/bin/qpdf"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_DIR}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_commands_reject_too_old_qpdf()
{
    local group exit_code output

    for group in "${GROUPS_USING_QPDF[@]}"; do
        exit_code=0
        output="$(PATH="${TEST_DIR}/bin:${PATH}" "command_${group}" help 2>&1)" || exit_code=$?

        assert_same "1" "${exit_code}" "${group}: exit code"
        assert_same "ERROR: qpdf 11 or newer is required (found 10.6.3)" "${output}"
    done

    exit_code=0
    output="$(PATH="${TEST_DIR}/bin:${PATH}" command_annotation_list "${ROOT_DIR}/tests/_data/annotations.pdf" 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_same "ERROR: qpdf 11 or newer is required (found 10.6.3)" "${output}"
}
