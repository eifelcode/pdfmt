function command_sort_help()
{
    cat <<TEXT
Reorder pages within a PDF file

Usage:
  pdfmt sort <command> [arguments]

Commands:
  duplex        Reorder a single PDF containing consecutive front and back scans
  move          Move specific pages to a new position within the PDF
  random        Shuffle the pages of a PDF into a random order
  reverse       Reverse the page order of a PDF
  swap          Swap two specific pages within a PDF

General Commands:
  help          Display this help message

TEXT
}
