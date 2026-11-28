function command_split()
{
    _qpdf_assert_supported_version || return $?

    local -r command="${1:-}"
    [[ -n "${command}" ]] && shift

    case "${command}" in
        all) command_split_all "$@" ;;
        length) command_split_length "$@" ;;
        range) command_split_range "$@" ;;

        help|--help|-h|'') command_split_help "$@" ;;
        *)  _log_error "Unknown command '$command'"; return 1; ;;
    esac
}
