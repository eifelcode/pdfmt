#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    export TEST_HOME="/tmp/bashunit_config_test_$$"
    export HOME="${TEST_HOME}"

    mkdir -p "${HOME}/.config/pdfmt"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_HOME}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_get_value()
{
    local config_file="${HOME}/.config/pdfmt/test.conf"

    cat > "${config_file}" <<EOF
test.value=hello world
test.number=123
test.color="#DC143C"
EOF

    assert_same "hello world" "$(_config_get_value "${config_file}" "test.value")"
    assert_same "123" "$(_config_get_value "${config_file}" "test.number")"
    assert_same "#DC143C" "$(_config_get_value "${config_file}" "test.color")"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_get_value_missing_key_or_file()
{
    local config_file="${HOME}/.config/pdfmt/test.conf"
    echo "test.value=1" > "${config_file}"

    local exit_code=0
    local output
    output="$(set -euo pipefail; _config_get_value "${config_file}" "test.unknown")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "" "${output}"

    exit_code=0
    output="$(set -euo pipefail; _config_get_value "${config_file}" "test.unknown" "fallback")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "fallback" "${output}"

    exit_code=0
    output="$(set -euo pipefail; _config_get_value "${HOME}/does-not-exist.conf" "test.value" "fallback")" || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_same "fallback" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_get_value_exact_key_match()
{
    local config_file="${HOME}/.config/pdfmt/test.conf"

    cat > "${config_file}" <<EOF
# test.value=commented
testXvalue=regex-match
test.value.other=prefix-match
test.value=first
test.value=last
EOF

    assert_same "last" "$(_config_get_value "${config_file}" "test.value")"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_get_value_quotes_and_whitespace()
{
    local config_file="${HOME}/.config/pdfmt/test.conf"

    cat > "${config_file}" <<EOF
test.spaces =   padded value
test.double="/path/with space/font.ttf"
test.single='single quoted'
test.inner=it's "fine"
test.equals=a=b=c
test.crlf=windows$(printf '\r')
test.empty=
EOF

    assert_same "padded value" "$(_config_get_value "${config_file}" "test.spaces")"
    assert_same "/path/with space/font.ttf" "$(_config_get_value "${config_file}" "test.double")"
    assert_same "single quoted" "$(_config_get_value "${config_file}" "test.single")"
    assert_same "it's \"fine\"" "$(_config_get_value "${config_file}" "test.inner")"
    assert_same "a=b=c" "$(_config_get_value "${config_file}" "test.equals")"
    assert_same "windows" "$(_config_get_value "${config_file}" "test.crlf")"
    assert_same "" "$(_config_get_value "${config_file}" "test.empty")"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_load_with_incomplete_config()
{
    echo "scan.device=only-device" > "${HOME}/.config/pdfmt/scan.conf"

    local exit_code=0
    (set -euo pipefail; _config_load_scan) || exit_code=$?
    assert_same "0" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_load_scan()
{
    cat > "${HOME}/.config/pdfmt/scan.conf" <<EOF
scan.device=test:scanner
scan.source.adf=TestADF
scan.source.flatbed=TestFlatbed
scan.resolution=600
scan.mode=Gray
scan.paper.format=A5
EOF

    _config_load_scan

    assert_same "test:scanner" "${SCAN_DEVICE}"
    assert_same "TestADF" "${SCAN_SOURCE_ADF}"
    assert_same "TestFlatbed" "${SCAN_SOURCE_FLATBED}"
    assert_same "600" "${SCAN_RESOLUTION}"
    assert_same "Gray" "${SCAN_MODE}"
    assert_same "A5" "${SCAN_PAPER_FORMAT}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_load_stamp_text()
{
    cat > "${HOME}/.config/pdfmt/stamp_text.conf" <<EOF
stamp.text.font.file=/tmp/test-font.ttf
stamp.text.font.size=42
stamp.text.font.color="#00FF00"
EOF

    _config_load_stamp_text

    assert_same "/tmp/test-font.ttf" "${STAMP_TEXT_FONT_FILE}"
    assert_same "42" "${STAMP_TEXT_FONT_SIZE}"
    assert_same "#00FF00" "${STAMP_TEXT_FONT_COLOR}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_config_load_ocr()
{
    cat > "${HOME}/.config/pdfmt/ocr.conf" <<EOF
ocr.language=foo
ocr.plugin=bar
EOF

    _config_load_ocr

    assert_same "foo" "${OCR_LANGUAGE}"
    assert_same "bar" "${OCR_PLUGIN}"
}
