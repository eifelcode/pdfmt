function command_scan_flatbed()
{
    if (( $# < 2 )); then
        cat <<TEXT
Scan documents from flatbed scanner into a new PDF

Usage:
  pdfmt scan flatbed <output file>

Examples:
  pdfmt scan flatbed output.pdf

TEXT
        return 0
    fi

    _command_scan_execute "$@"
}
