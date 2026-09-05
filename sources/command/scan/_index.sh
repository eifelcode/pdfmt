function command_scan()
{
    # Check dependencies for 'scan' command
    assert_installed convert    # Part of ImageMagick
    assert_installed scanimage

    local -r command="${1:-}"

    case "${command}" in
        adf) command_scan_adf "$@" ;;
        flatbed) command_scan_flatbed "$@" ;;

        help|--help|-h|'') command_scan_help "$@" ;;
        *)  log_error "Unknown command '$command'"; return 1; ;;
    esac
}
