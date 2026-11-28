#!/usr/bin/env bash
# =====================================================================================================================
# Script: print-dependency-versions.sh
#
# Description:
# Prints the versions of all tools pdfmt and its build/test process depend on. Missing tools are reported as
# "not installed"; the script never fails. The output is meant as a hint when something behaves differently
# locally and in the CI.
#
# Usage:
# tools/print-dependency-versions.sh
# =====================================================================================================================

# Prints "<name>  <version>" for a tool.
#
# Arguments:
#   $1: Display name
#   $2: Program to look for in $PATH
#   $3: Version command (evaluated); its output is filtered by $4
#   $4: (optional) sed expression to extract the version from the output (default: first line)
function print_version()
{
    local -r name="${1}"
    local -r program="${2}"
    local -r version_command="${3}"
    local -r filter="${4:-}"

    local version=""
    if command -v "${program}" >/dev/null 2>&1; then
        local output
        output="$(eval "${version_command}" 2>&1 | sed $'s/\x1b\\[[0-9;]*m//g' || true)"
        if [[ -n "${filter}" ]]; then
            version="$(printf '%s\n' "${output}" | sed -n "${filter}" | head -n 1 || true)"
        else
            version="$(printf '%s\n' "${output}" | head -n 1 || true)"
        fi
        [[ -n "${version}" ]] || version="installed (version unknown)"
    else
        version="not installed"
    fi

    printf '  %-14s %s\n' "${name}" "${version}"
}

function main()
{
    echo "Dependency versions:"
    print_version "OS"           uname       "uname -sr"
    print_version "bash"         bash        "bash --version"
    print_version "make"         make        "make --version"
    print_version "pdftk"        pdftk       "pdftk --version"
    print_version "qpdf"         qpdf        "qpdf --version"
    print_version "jq"           jq          "jq --version"
    if command -v magick >/dev/null 2>&1; then
        print_version "imagemagick" magick   "magick -version"                       's/^Version: //p'
    else
        print_version "imagemagick" convert  "convert -version"                      's/^Version: //p'
    fi
    print_version "pdftotext"    pdftotext   "pdftotext -v"
    print_version "scanimage"    scanimage   "scanimage --version"
    print_version "ocrmypdf"     ocrmypdf    "ocrmypdf --version"
    print_version "tesseract"    tesseract   "tesseract --version"
    print_version "shellcheck"   shellcheck  "shellcheck --version"                 's/^version: //p'

    local bashunit="lib/bashunit"
    if [[ -x "${bashunit}" ]]; then
        print_version "bashunit"  "${bashunit}" "${bashunit} --version"
    else
        print_version "bashunit"  bashunit    "bashunit --version"
    fi
}

main "$@"
