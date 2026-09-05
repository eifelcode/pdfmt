#######################################################################################################################
# Logs a info message
#
# Usage:
#   log_info "file created"
#
# Arguments:
#   $1: The info message to log
# Outputs:
#   Outputs a message to STDOUT
#######################################################################################################################
function log_info()
{
    local -r message="${1:-}"
    echo "INFO: ${message}"
}

#######################################################################################################################
# Logs a warning message
#
# Usage:
#   log_warning "file not found"
#
# Arguments:
#   $1: The warning message to log
# Outputs:
#   Outputs a message to STDERR
#######################################################################################################################
function log_warning()
{
    local -r message="${1:-}"
    echo "WARNING: ${message}" >&2
}

#######################################################################################################################
# Logs a error message
#
# Usage:
#   log_error "file not found"
#
# Arguments:
#   $1: The error message to log
# Outputs:
#   Outputs a message to STDERR
#######################################################################################################################
function log_error()
{
    local -r message="${1:-}"
    echo "ERROR: ${message}" >&2
}
