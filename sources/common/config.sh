function _config_get_value()
{
    local -r file="${1}"
    local -r key="${2}"
    [[ -f "$file" ]] && grep "^${key}=" "$file" | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs
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
