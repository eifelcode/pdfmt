function command_extract_help()
{
    cat <<TEXT
Save specific pages into a new PDF

Usage:
  pdfmt extract <command> [arguments]

Commands:
  even          Extract all even-numbered pages
  odd           Extract all odd-numbered pages
  range         Extract a specific range of pages (e.g., 1-5) into a new PDF

General Commands:
  help          Display this help message

TEXT
}
