function command_merge_help()
{
    cat <<TEXT
Combine PDFs into a single document

Usage:
  pdfmt merge <command> [arguments]

Commands:
  all           Combine PDFs into a single document
  duplex        Interleave two PDFs (front/back scans) into one duplex document
  insert        Insert a PDF into another document at a specific page

General Commands:
  help          Display this help message

TEXT
}
