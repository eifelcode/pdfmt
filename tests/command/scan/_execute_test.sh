#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    export TEST_HOME="/tmp/bashunit_config_test_$$"
    export HOME="${TEST_HOME}"

    mkdir -p "${TEST_HOME}/.config/pdfmt"
    mkdir -p "${TEST_HOME}/bin"

    cat > "${TEST_HOME}/.config/pdfmt/scan.conf" <<EOF
scan.device=test:scanner
scan.source.adf=ADF
scan.source.flatbed=Flatbed
scan.resolution=300
scan.mode=Color
scan.paper.format=A4
EOF

    cat > "${TEST_HOME}/bin/scanimage" <<EOF
#!/usr/bin/env bash

output_file=

for argument in "\$@"; do
    if [[ "\$argument" == --batch=* ]]; then
        output_file="\${argument#--batch=}"
    fi
done

if [[ -n "\${output_file}" ]]; then
    output_file="\${output_file//%03d/001}"
    cp "\${SCAN_TEST_IMAGE:-${ROOT_DIR}/tests/_data/scan.png}" "\${output_file}"
else
    cat "\${SCAN_TEST_IMAGE:-${ROOT_DIR}/tests/_data/scan.png}"
fi
EOF

    chmod +x "${TEST_HOME}/bin/scanimage"

    export PATH="${TEST_HOME}/bin:${PATH}"

    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/scan/_execute.sh"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_HOME}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_scan_execute_adf()
{
    local exit_code=0
    local -r output_file="${TEST_HOME}/scan.pdf"

    _command_scan_execute \
        adf \
        "${output_file}" || exit_code=$?

    assert_same "0" "${exit_code}"
    assert_file_exists "${output_file}"

    local -r num_pages="$(_pdf_get_num_pages "${output_file}")"

    assert_same "1" "${num_pages}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_scan_execute_scanimage_fails()
{
    local exit_code=0
    local -r output_file="${TEST_HOME}/scan.pdf"

    cat > "${TEST_HOME}/bin/scanimage" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

    chmod +x "${TEST_HOME}/bin/scanimage"

    _command_scan_execute \
        adf \
        "${output_file}" || exit_code=$?

    assert_same "1" "${exit_code}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_scan_execute_page_size_independent_of_png_resolution()
{
    local exit_code=0
    local -r output_file="${TEST_HOME}/scan.pdf"

    # A4 scan at 300 DPI; scanners store the resolution in pixels per centimeter (118.11 px/cm = 300 DPI)
    export SCAN_TEST_IMAGE="${TEST_HOME}/scan-300dpi.png"
    _imagemagick_convert -size 2480x3508 xc:white -units PixelsPerCentimeter -density 118.11 "${SCAN_TEST_IMAGE}"

    _command_scan_execute \
        flatbed \
        "${output_file}" || exit_code=$?
    unset SCAN_TEST_IMAGE

    assert_same "0" "${exit_code}"
    assert_file_exists "${output_file}"
    assert_contains "595 x 842 pts (A4)" "$(pdfinfo "${output_file}" | grep "Page size")"
}
