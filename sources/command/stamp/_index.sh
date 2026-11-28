function command_stamp()
{
    # Check dependencies for 'stamp' command
    _imagemagick_assert_installed || return $?
    _qpdf_assert_supported_version || return $?

    local -r command="${1:-}"
    [[ -n "${command}" ]] && shift

    case "${command}" in
        text) command_stamp_text "$@" ;;

        help|--help|-h|'') command_stamp_help "$@" ;;
        *)  _log_error "Unknown command '$command'"; return 1; ;;
    esac
}
