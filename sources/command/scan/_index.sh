function command_scan()
{
    # Check dependencies for 'scan' command
    _imagemagick_assert_installed || return $?
    _assert_is_installed scanimage || return $?

    local -r command="${1:-}"

    case "${command}" in
        adf) command_scan_adf "$@" ;;
        flatbed) command_scan_flatbed "$@" ;;

        help|--help|-h|'') command_scan_help "$@" ;;
        *)  _log_error "Unknown command '$command'"; return 1; ;;
    esac
}
