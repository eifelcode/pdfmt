function command_scan_adf()
{
    if (( $# < 2 )); then
        cat <<TEXT
Scan documents from ADF (automatic document feeder) into a new PDF

Usage:
  pdfmt scan adf <output file>

Examples:
  pdfmt scan adf output.pdf

TEXT
        return 0
    fi

    _command_scan_execute "$@"
}
