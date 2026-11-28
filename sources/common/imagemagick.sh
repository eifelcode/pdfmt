#######################################################################################################################
# Asserts that ImageMagick is installed.
#
# ImageMagick 7 provides the unified `magick` command; the legacy tools `convert` and `identify` are deprecated there.
# ImageMagick 6 provides only the legacy tools. Both variants are supported.
#
# Usage:
#   _imagemagick_assert_installed
#
# Outputs:
#   Outputs a message to STDERR if the assertion fails
# Returns:
#   0 on success, 1 on failure
#######################################################################################################################
function _imagemagick_assert_installed()
{
    if command -v magick >/dev/null 2>&1; then
        return 0
    fi

    _assert_is_installed convert "ImageMagick is not installed (neither \"magick\" nor \"convert\" found in \"\$PATH\")" || return $?
    _assert_is_installed identify "ImageMagick is not installed (\"identify\" not found in \"\$PATH\")" || return $?
}

#######################################################################################################################
# Runs ImageMagick's convert functionality: `magick` (ImageMagick 7) if available, otherwise `convert` (ImageMagick 6).
#
# Usage:
#   _imagemagick_convert input.png -quality 85 output.pdf
#
# Arguments:
#   $@: Arguments passed unchanged to convert
# Returns:
#   The exit code of the executed program
#######################################################################################################################
function _imagemagick_convert()
{
    if command -v magick >/dev/null 2>&1; then
        magick "$@"
    else
        convert "$@"
    fi
}

#######################################################################################################################
# Runs ImageMagick's identify functionality: `magick identify` (ImageMagick 7) if available, otherwise `identify`
# (ImageMagick 6).
#
# Usage:
#   _imagemagick_identify -format '%wx%h\n' input.pdf
#
# Arguments:
#   $@: Arguments passed unchanged to identify
# Returns:
#   The exit code of the executed program
#######################################################################################################################
function _imagemagick_identify()
{
    if command -v magick >/dev/null 2>&1; then
        magick identify "$@"
    else
        identify "$@"
    fi
}
