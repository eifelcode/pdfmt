#######################################################################################################################
# Reads the value of a key from a simple key=value config file.
#
# - Only exact key matches count (the key is not treated as a regex).
# - If a key occurs multiple times, the last one wins.
# - Surrounding whitespace and one pair of surrounding quotes (" or ') are removed; inner quotes are kept.
# - A missing file or key is not an error: the (optional) default is printed instead.
#
# Usage:
#   _config_get_value "$file" "scan.device"
#   _config_get_value "$file" "scan.resolution" "300"
#
# Arguments:
#   $1: Config file
#   $2: Key
#   $3: (optional) Default value if the file or key does not exist
# Outputs:
#   The value
# Returns:
#   Always 0
#######################################################################################################################
function _config_get_value()
{
    local -r file="${1}"
    local -r key="${2}"
    local value="${3:-}"

    if [[ -f "${file}" ]]; then
        local line line_key line_value
        while IFS= read -r line || [[ -n "${line}" ]]; do
            line="${line%$'\r'}"
            [[ "${line}" == *=* ]] || continue

            line_key="${line%%=*}"
            line_key="${line_key#"${line_key%%[![:space:]]*}"}"
            line_key="${line_key%"${line_key##*[![:space:]]}"}"
            [[ "${line_key}" == "${key}" ]] || continue

            line_value="${line#*=}"
            line_value="${line_value#"${line_value%%[![:space:]]*}"}"
            line_value="${line_value%"${line_value##*[![:space:]]}"}"

            if [[ "${line_value}" =~ ^\"(.*)\"$ || "${line_value}" =~ ^\'(.*)\'$ ]]; then
                line_value="${BASH_REMATCH[1]}"
            fi
            value="${line_value}"
        done < "${file}"
    fi

    printf '%s\n' "${value}"
}

function _config_load_scan()
{
    local -r config_dir="${HOME}/.config/pdfmt"
    local -r config_file="${config_dir}/scan.conf"

    if [[ ! -f "${config_file}" ]]; then
        mkdir -p "$config_dir"
        local -r auto_device="$(scanimage -f "%d" 2>/dev/null | head -n 1 || true)"
        cat <<EOF > "$config_file"
# Config for command: scan
# =====================================================================================================================
# The name/path to your default scanner device. This can be determined by: scanimage -f "%d" | head -n 1
scan.device=${auto_device}

# Sources for Automated Document Feeder and Flatbed
scan.source.adf=ADF
scan.source.flatbed=Flatbed

# Resolution in DPI (100, 200, 300, 600)
scan.resolution=300

# Scan mode (e.g. Lineart, Gray, Color)
scan.mode=Color

# Default paper format (e.g., A4, A5)
scan.paper.format=A4

EOF
    fi

    local value=
    value="$(_config_get_value "$config_file" "scan.device")";          export SCAN_DEVICE="$value"
    value="$(_config_get_value "$config_file" "scan.source.adf")";      export SCAN_SOURCE_ADF="$value"
    value="$(_config_get_value "$config_file" "scan.source.flatbed")";  export SCAN_SOURCE_FLATBED="$value"
    value="$(_config_get_value "$config_file" "scan.resolution")";      export SCAN_RESOLUTION="$value"
    value="$(_config_get_value "$config_file" "scan.mode")";            export SCAN_MODE="$value"
    value="$(_config_get_value "$config_file" "scan.paper.format")";    export SCAN_PAPER_FORMAT="$value"
}

function _config_load_stamp_text()
{
    local -r config_dir="${HOME}/.config/pdfmt"
    local -r config_file="${config_dir}/stamp_text.conf"

    if [[ ! -f "${config_file}" ]]; then
        mkdir -p "$config_dir"

        local font_file=
        if [[ "$(uname)" == "Darwin" ]]; then
            font_file="/System/Library/Fonts/Helvetica.ttc"
        else
            font_file="$(find /usr/share/fonts -name "*DejaVuSans-Bold*.ttf" | head -n 1)"
        fi


        cat <<EOF > "$config_file"
# Config for command: stamp text
# =====================================================================================================================
# Absolute path to font file
stamp.text.font.file="${font_file}"

# Font size for stamp
stamp.text.font.size=22

# Used font color for stamp (ImageMagic compatible value)
stamp.text.font.color="#DC143C"

EOF
    fi

    local value=
    value="$(_config_get_value "$config_file" "stamp.text.font.file")";     export STAMP_TEXT_FONT_FILE="$value"
    value="$(_config_get_value "$config_file" "stamp.text.font.size")";     export STAMP_TEXT_FONT_SIZE="$value"
    value="$(_config_get_value "$config_file" "stamp.text.font.color")";    export STAMP_TEXT_FONT_COLOR="$value"
}

function _config_load_workflow()
{
    local -r config_dir="${HOME}/.config/pdfmt"
    local -r config_file="${config_dir}/workflow.conf"
    local -r workflow_dir="${HOME}/.local/share/pdfmt/workflows"

    if [[ ! -f "${config_file}" ]]; then
        mkdir -p "$config_dir"
        cat <<EOF > "$config_file"
# Config for command: workflow
# =====================================================================================================================
# List of directories separated by : where your workflow scripts are located.
workflow.paths=${workflow_dir}

EOF

        mkdir -p "${workflow_dir}"
        cat <<EOF > "${workflow_dir}/echo"
#!/usr/bin/env bash
# =====================================================================================================================
# Write arguments to the standard output
#
# Usage:
#   echo [string ...]
#
# Workflow steps:
#   - Writes any specified argument to the standard output
# =====================================================================================================================

echo "\$@"

EOF
        chmod +x "${workflow_dir}/echo"
    fi

    local value=
    value="$(_config_get_value "$config_file" "workflow.paths")";       export WORKFLOW_PATHS="$value"
}

function _config_load_ocr()
{
    local -r config_dir="${HOME}/.config/pdfmt"
    local -r config_file="${config_dir}/ocr.conf"

    if [[ ! -f "${config_file}" ]]; then
        mkdir -p "$config_dir"
        cat <<EOF > "$config_file"
# Config for command: ocr
# =====================================================================================================================
# Language codes used for OCR text recognition.
ocr.language=eng

# Used OCRmyPDF plugin.
# Default: -empty- (Tesseract will be used)
# Possible options if installed:
# - ocrmypdf_rapidocr
# - ocrmypdf_easyocr
ocr.plugin=

EOF
    fi

    local value=
    value="$(_config_get_value "$config_file" "ocr.language")"; export OCR_LANGUAGE="$value"
    value="$(_config_get_value "$config_file" "ocr.plugin")";   export OCR_PLUGIN="$value"
}
