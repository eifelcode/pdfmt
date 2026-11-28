function command_scan_adf()
{
    if (( $# < 2 )); then
        _usage $(( $# - 1 )) <<TEXT
Scan documents from ADF (automatic document feeder) into a new PDF

Usage:
  pdfmt scan adf <output file>

Examples:
  pdfmt scan adf output.pdf

TEXT
        return $?
    fi

    _command_scan_execute "$@"
}
