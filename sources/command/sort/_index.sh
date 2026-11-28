function command_sort()
{
    _qpdf_assert_supported_version || return $?

    local -r command="${1:-}"
    [[ -n "${command}" ]] && shift

    case "${command}" in
        duplex) command_sort_duplex "$@" ;;
        move) command_sort_move "$@" ;;
        random) command_sort_random "$@" ;;
        reverse) command_sort_reverse "$@" ;;
        swap) command_sort_swap "$@" ;;

        help|--help|-h|'') command_sort_help "$@" ;;
        *)  _log_error "Unknown command '$command'"; return 1; ;;
    esac
}
