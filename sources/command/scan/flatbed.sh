function command_scan_flatbed()
{
    if (( $# < 2 )); then
        _usage $(( $# - 1 )) <<TEXT
Scan documents from flatbed scanner into a new PDF

Usage:
  pdfmt scan flatbed <output file>

Examples:
  pdfmt scan flatbed output.pdf

TEXT
        return $?
    fi

    _command_scan_execute "$@"
}
