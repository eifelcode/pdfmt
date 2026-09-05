function command_remove_help()
{
    cat <<TEXT
Delete specific pages from a PDF

Usage:
  pdfmt remove <command> [arguments]

Commands:
  even          Remove all even-numbered pages
  odd           Remove all odd-numbered pages
  range         Remove a specific range of pages (e.g., 1-5)

General Commands:
  help          Display this help message

TEXT
}
