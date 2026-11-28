#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    export TEST_DIR="/tmp/bashunit_test_$$"
    mkdir -p "${TEST_DIR}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_DIR}"
}

# Creates a fake qpdf in ${TEST_DIR}/<name> that reports the given version and prints its arguments otherwise.
function create_fake_qpdf()
{
    local -r name="${1}"
    local -r version_output="${2}"

    mkdir -p "${TEST_DIR}/${name}"
    cat > "${TEST_DIR}/${name}/qpdf" <<EOF2
#!/bin/bash
if [[ "\${1:-}" == "--version" ]]; then
    printf '%s\n' "${version_output}" "Run qpdf --copyright to see copyright and license information."
else
    echo "qpdf \$*"
fi
EOF2
    chmod +x "${TEST_DIR}/${name}/qpdf"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_qpdf_get_version()
{
    create_fake_qpdf "v12" "qpdf version 12.3.2"
    create_fake_qpdf "v10" "qpdf version 10.6.3"
    create_fake_qpdf "v11" "qpdf version 11.0"
    create_fake_qpdf "garbage" "something unexpected"

    assert_same "12.3.2" "$(PATH="${TEST_DIR}/v12:${PATH}" _qpdf_get_version)"
    assert_same "10.6.3" "$(PATH="${TEST_DIR}/v10:${PATH}" _qpdf_get_version)"
    assert_same "11.0" "$(PATH="${TEST_DIR}/v11:${PATH}" _qpdf_get_version)"

    local exit_code=0
    local output
    output="$(PATH="${TEST_DIR}/garbage:${PATH}" _qpdf_get_version 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_same "ERROR: Unable to determine the qpdf version" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_qpdf_assert_supported_version()
{
    create_fake_qpdf "v12" "qpdf version 12.3.2"
    create_fake_qpdf "v11" "qpdf version 11.0.0"
    create_fake_qpdf "v10" "qpdf version 10.6.3"

    local exit_code=0
    local output

    PATH="${TEST_DIR}/v12:${PATH}" _qpdf_assert_supported_version || exit_code=$?
    assert_same "0" "${exit_code}"

    exit_code=0
    PATH="${TEST_DIR}/v11:${PATH}" _qpdf_assert_supported_version || exit_code=$?
    assert_same "0" "${exit_code}"

    exit_code=0
    output="$(PATH="${TEST_DIR}/v10:${PATH}" _qpdf_assert_supported_version 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_same "ERROR: qpdf 11 or newer is required (found 10.6.3)" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_qpdf_assert_supported_version_not_installed()
{
    mkdir -p "${TEST_DIR}/empty"
    ln -s "$(command -v bash)" "${TEST_DIR}/empty/bash"

    local exit_code=0
    local output
    output="$(PATH="${TEST_DIR}/empty" _qpdf_assert_supported_version 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_contains "qpdf" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_qpdf_json_requests_fixed_version()
{
    create_fake_qpdf "v12" "qpdf version 12.3.2"

    assert_same "qpdf --json=2 input.pdf" "$(PATH="${TEST_DIR}/v12:${PATH}" _qpdf_json input.pdf)"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_qpdf_json_format()
{
    # Real qpdf: the structure the annotation commands rely on (.qpdf[1] holds the objects)
    local exit_code=0
    local output
    output="$(_qpdf_json "${ROOT_DIR}/tests/_data/annotations.pdf" | jq -r '[.version, (.qpdf[1] | type)] | join(" ")')" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "2 object" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_qpdf_run()
{
    local exit_code

    # qpdf exit codes: 0 success, 2 error, 3 success with warnings
    local code
    for code in 0 2 3; do
        mkdir -p "${TEST_DIR}/exit${code}"
        printf '#!/bin/bash\necho "qpdf $*"\nexit %s\n' "${code}" > "${TEST_DIR}/exit${code}/qpdf"
        chmod +x "${TEST_DIR}/exit${code}/qpdf"
    done

    exit_code=0
    assert_same "qpdf --empty out.pdf" "$(PATH="${TEST_DIR}/exit0:${PATH}" _qpdf_run --empty out.pdf)" || exit_code=$?
    assert_same "0" "${exit_code}"

    # warnings are no failure
    exit_code=0
    PATH="${TEST_DIR}/exit3:${PATH}" _qpdf_run --empty out.pdf >/dev/null || exit_code=$?
    assert_same "0" "${exit_code}"

    # errors are passed through
    exit_code=0
    PATH="${TEST_DIR}/exit2:${PATH}" _qpdf_run --empty out.pdf >/dev/null || exit_code=$?
    assert_same "2" "${exit_code}"
}
