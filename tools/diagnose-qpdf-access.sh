#!/usr/bin/env bash
# =====================================================================================================================
# Script: diagnose-qpdf-access.sh
#
# Description:
# Diagnoses why qpdf may not be able to read a temporary JSON file ("open /tmp/tmp.XXXX: Permission denied").
# Reads a qpdf JSON file via "--update-from-json" from several locations and with files created in different ways,
# and prints the security context of the shell and of the files. The script never fails.
#
# Usage:
# tools/diagnose-qpdf-access.sh
# =====================================================================================================================

function section()
{
    echo
    echo "=== $* ==="
}

# Tries "qpdf --update-from-json" with the JSON file at the given path.
function try_json_file()
{
    local -r label="${1}"
    local -r json_file="${2}"
    local -r pdf="${3}"

    local output
    local exit_code=0
    output="$(qpdf --update-from-json="${json_file}" "${pdf}" "${WORK_DIR}/out.pdf" 2>&1)" || exit_code=$?
    rm -f "${WORK_DIR}/out.pdf"
    printf '  %-34s qpdf rc=%s %s\n' "${label}" "${exit_code}" "${output}"
    printf '  %-34s %s\n' "" "$(stat -c 'mode=%a owner=%U inode=%i ctx=%C' "${json_file}" 2>/dev/null || stat -f 'mode=%Lp owner=%Su' "${json_file}" 2>&1)"
}

function main()
{
    WORK_DIR="$(mktemp -d)"

    section "Environment"
    echo "id:            $(id)"
    echo "umask:         $(umask)"
    echo "TMPDIR:        ${TMPDIR:-<unset>}"
    echo "RUNNER_TEMP:   ${RUNNER_TEMP:-<unset>}"
    echo "PWD:           ${PWD}"
    echo "qpdf:          $(command -v qpdf) ($(qpdf --version 2>&1 | head -n 1))"
    echo "mktemp:        $(command -v mktemp) ($(mktemp --version 2>&1 | head -n 1))"
    echo "kernel:        $(uname -sr)"

    section "Security modules"
    echo "AppArmor label of this shell: $(cat /proc/self/attr/current 2>&1)"
    echo "AppArmor enabled:             $(cat /sys/module/apparmor/parameters/enabled 2>&1)"
    echo "LSMs:                         $(cat /sys/kernel/security/lsm 2>&1)"
    echo "fs.protected_regular:         $(cat /proc/sys/fs/protected_regular 2>&1)"
    echo "AppArmor profiles for qpdf:   $(ls /etc/apparmor.d 2>/dev/null | grep -i -E 'qpdf|usr\.bin\.q' || echo none)"
    echo "mounts of /tmp:               $(grep -E ' /tmp ' /proc/mounts 2>/dev/null || echo 'no separate mount')"
    echo "ls -ld /tmp:                  $(ls -ld /tmp)"

    section "Test PDF and JSON"
    local -r pdf="${WORK_DIR}/test.pdf"
    gs -q -dBATCH -dNOPAUSE -sDEVICE=pdfwrite -sOutputFile="${pdf}" -c showpage 2>&1 || true
    local -r json="${WORK_DIR}/test.json"
    qpdf --json=2 "${pdf}" > "${json}"
    echo "pdf: $(ls -l "${pdf}")"
    echo "json: $(ls -l "${json}")"

    section "qpdf --update-from-json with the JSON file in different places"
    local dir
    for dir in "${WORK_DIR}" /tmp "${PWD}" "${HOME:-/nonexistent}" "${RUNNER_TEMP:-/nonexistent}" /dev/shm /var/tmp; do
        [[ -d "${dir}" && -w "${dir}" ]] || { printf '  %-34s skipped (not a writable directory)\n' "${dir}"; continue; }

        local file

        # created with mktemp (like pdfmt does)
        file="$(mktemp -p "${dir}")" || continue
        cp "${json}" "${file}"
        try_json_file "mktemp in ${dir}" "${file}" "${pdf}"
        rm -f "${file}"

        # created with a plain redirect
        file="${dir}/pdfmt-diagnose-$$.json"
        cp "${json}" "${file}"
        try_json_file "cp in ${dir}" "${file}" "${pdf}"
        rm -f "${file}"
    done

    section "qpdf reading the input PDF in /tmp"
    cp "${pdf}" "/tmp/pdfmt-diagnose-$$.pdf" && qpdf --check "/tmp/pdfmt-diagnose-$$.pdf" 2>&1 | tail -n 1
    rm -f "/tmp/pdfmt-diagnose-$$.pdf"

    rm -rf "${WORK_DIR}"
}

main "$@"
exit 0
