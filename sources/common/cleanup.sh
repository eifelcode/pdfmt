FILES_TO_CLEANUP=()
function _cleanup()
{
    if (( ${#FILES_TO_CLEANUP[@]} > 0 )); then
        rm -rf -- "${FILES_TO_CLEANUP[@]}"
    fi
}
