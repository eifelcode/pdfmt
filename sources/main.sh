function main()
{
    set -euo pipefail

    trap _cleanup EXIT INT TERM

    # Check core dependencies for PDF manipulation
    assert_installed awk
    assert_installed basename
    assert_installed cat
    assert_installed find
    assert_installed grep
    assert_installed head
    assert_installed mktemp
    assert_installed pdftk
    assert_installed sed
    assert_installed seq
    assert_installed tr
    assert_installed xargs

    local -r command="${1:-}"
    [[ -n "${command}" ]] && shift

    case "${command}" in
        extract) command_extract "$@" ;;
        merge) command_merge "$@" ;;
        remove) command_remove "$@" ;;
        scan) command_scan "$@" ;;
        sort) command_sort "$@" ;;
        split) command_split "$@" ;;
        stamp) command_stamp "$@" ;;

        version|--version|-v) command_version "$@" ;;
        help|--help|-h|'') command_help "$@" ;;
        *)  log_error "Unknown command '$command'"; return 1; ;;
    esac
}
