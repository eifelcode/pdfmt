# The qpdf JSON format differs between qpdf versions ("--json" without a version means "latest", which can change
# with a qpdf update). All JSON handling in pdfmt is written for this version, so it is always requested explicitly.
readonly QPDF_JSON_VERSION=2

# Minimum supported qpdf version. All commands that use qpdf require it (among others, the explicit JSON version
# selection "--json=N" and JSON version 2 are available since qpdf 11).
readonly QPDF_MIN_MAJOR_VERSION=11

#######################################################################################################################
# Determines and prints the version of the installed qpdf (e.g. "12.3.2").
#
# Usage:
#   _qpdf_get_version
#
# Outputs:
#   - Outputs a message to STDERR if the version can not be determined
#   - The version
# Returns:
#   0 on success, 1 on failure
#######################################################################################################################
function _qpdf_get_version()
{
    local first_line
    first_line="$(qpdf --version 2>/dev/null | head -n 1)" || true

    if [[ ! "${first_line}" =~ ([0-9]+\.[0-9]+(\.[0-9]+)?) ]]; then
        _log_error "Unable to determine the qpdf version"
        return 1
    fi

    echo "${BASH_REMATCH[1]}"
}

#######################################################################################################################
# Asserts that qpdf is installed and at least in the minimum supported version (QPDF_MIN_MAJOR_VERSION).
#
# Usage:
#   _qpdf_assert_supported_version
#
# Outputs:
#   Outputs a message to STDERR if the assertion fails
# Returns:
#   0 on success, 1 on failure
#######################################################################################################################
function _qpdf_assert_supported_version()
{
    _assert_is_installed qpdf || return $?

    local version
    version="$(_qpdf_get_version)" || return $?

    local -r major="${version%%.*}"
    if (( major < QPDF_MIN_MAJOR_VERSION )); then
        _log_error "qpdf ${QPDF_MIN_MAJOR_VERSION} or newer is required (found ${version})"
        return 1
    fi
}

#######################################################################################################################
# Prints the given PDF file as qpdf JSON in the fixed version QPDF_JSON_VERSION.
#
# Usage:
#   _qpdf_json "input.pdf" | jq ...
#
# Arguments:
#   $1: Input file
# Outputs:
#   The qpdf JSON
# Returns:
#   The exit code of qpdf
#######################################################################################################################
function _qpdf_json()
{
    qpdf "--json=${QPDF_JSON_VERSION}" "${1}"
}

#######################################################################################################################
# Runs qpdf. Exit code 3 of qpdf means "finished with warnings"; the output has been written in that case, so it is
# not treated as failure (the warnings are still printed by qpdf to STDERR).
#
# Usage:
#   _qpdf_run --empty --pages "input.pdf" 1-3 -- "output.pdf"
#
# Arguments:
#   $@: Arguments passed unchanged to qpdf
# Returns:
#   0 if qpdf succeeded (with or without warnings), otherwise the exit code of qpdf
#######################################################################################################################
function _qpdf_run()
{
    local exit_code=0
    qpdf "$@" || exit_code=$?

    if (( exit_code == 3 )); then
        return 0
    fi

    return "${exit_code}"
}
