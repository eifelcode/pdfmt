#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/main.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/version.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/annotation/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/annotation/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/extract/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/extract/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/merge/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/merge/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/ocr/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/ocr/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/remove/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/remove/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/scan/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/scan/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/sort/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/sort/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/split/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/split/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/stamp/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/stamp/help.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/workflow/_index.sh"
    # shellcheck disable=SC1091     # ROOT_DIR is provided by the bootstrap.
    source "$ROOT_DIR/sources/command/workflow/help.sh"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    :
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_command_main()
{
    local exit_code=0
    local output

    # shellcheck disable=SC2034         # will be used in main
    VERSION=0.0.0

    output=$(main "") || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt <command>" "${output}"

    output=$(main help) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt <command> <subcommand> [arguments]" "${output}"

    output=$(main version) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "$VERSION" "${output}"

    output=$(main annotation) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt annotation <command> [arguments]" "${output}"

    output=$(main extract) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt extract <command> [arguments]" "${output}"

    output=$(main merge) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt merge <command> [arguments]" "${output}"

    output=$(main ocr) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt ocr <command> [arguments]" "${output}"

    output=$(main remove) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt remove <command> [arguments]" "${output}"

    output=$(main scan) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt scan <command> [arguments]" "${output}"

    output=$(main sort) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt sort <command> [arguments]" "${output}"

    output=$(main split) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt split <command> [arguments]" "${output}"

    output=$(main stamp) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt stamp <command> [arguments]" "${output}"

    output=$(main workflow) || exit_code=$?
    assert_same "0" "${exit_code}"
    assert_contains "pdfmt workflow <command> [arguments]" "${output}"

    output=$(main foobar 2>&1) || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_same "ERROR: Unknown command 'foobar'" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_main_signal_stops_script_and_cleans_up()
{
    local signal
    local expected_code

    if ! command -v perl >/dev/null 2>&1; then
        bashunit::skip "perl is required to reset the signal dispositions"
        return
    fi

    for signal in INT TERM; do
        expected_code=130
        [[ "${signal}" == "TERM" ]] && expected_code=143

        local marker="${TMPDIR:-/tmp}/pdfmt_signal_test_$$_${signal}"
        touch "${marker}"

        local exit_code=0
        local output
        # Background jobs (like tests run by bashunit) start with SIGINT/SIGQUIT ignored, and an ignored signal
        # can not be trapped by the child shell. Reset the signal dispositions via perl before starting bash.
        output="$(perl -e '$SIG{INT} = "DEFAULT"; $SIG{TERM} = "DEFAULT"; exec @ARGV' bash -c '
            for f in "$1"/sources/common/*.sh "$1"/sources/main.sh; do source "$f"; done
            # shellcheck disable=SC2317
            command_version() { FILES_TO_CLEANUP+=("$2"); kill -s "$1" $$; echo "continued"; }
            main version "$2" "$3"
        ' _ "${ROOT_DIR}" "${signal}" "${marker}" 2>&1)" || exit_code=$?

        assert_same "${expected_code}" "${exit_code}"
        assert_not_contains "continued" "${output}"
        assert_file_not_exists "${marker}"
    done
}
