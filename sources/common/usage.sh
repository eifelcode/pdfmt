#######################################################################################################################
# Prints the usage text of a command, which is read from STDIN.
#
# - Called without any argument the text is a help request: it is written to STDOUT, the exit code is 0.
# - Called with some, but not all required arguments the call is wrong: "ERROR: Missing arguments" and the text are
#   written to STDERR, the exit code is 1. Scripts and workflows can detect the incomplete call this way.
#
# Usage:
#   if (( $# < 2 )); then
#       _usage $# <<TEXT
#   Usage: pdfmt foo <input file> <output file>
#   TEXT
#       return $?
#   fi
#
# Arguments:
#   $1: Number of arguments the user gave to the command
#   STDIN: The usage text
# Outputs:
#   The usage text to STDOUT (help request) or STDERR (missing arguments)
# Returns:
#   0 for a help request, 1 for missing arguments
#######################################################################################################################
function _usage()
{
    local -r num_args="${1:-0}"

    if (( num_args == 0 )); then
        cat
        return 0
    fi

    _log_error "Missing arguments"
    cat >&2
    return 1
}
