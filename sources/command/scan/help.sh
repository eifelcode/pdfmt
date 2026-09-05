function command_scan_help()
{
    cat <<TEXT
Create PDFs directly from a scanner

Usage:
  pdfmt scan <command> [arguments]

Commands:
  adf           Scan documents from ADF (automatic document feeder) into a new PDF
  flatbed       Scan documents from flatbed scanner into a new PDF

General Commands:
  help          Display this help message

TEXT
}
