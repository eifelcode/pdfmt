function command_split_help()
{
    cat <<TEXT
Split a PDF into multiple files

Usage:
  pdfmt split <command> [arguments]

Commands:
  all           Split a PDF into separate files, one for each page
  length        Split a PDF into chunks of a fixed number of pages
  range         Split a PDF into multiple files based on page ranges

General Commands:
  help          Display this help message

TEXT
}
