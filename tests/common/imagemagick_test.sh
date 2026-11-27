#!/usr/bin/env bash

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function set_up()
{
    export TEST_DIR="/tmp/bashunit_test_$$"
    mkdir -p "${TEST_DIR}/im6" "${TEST_DIR}/im7" "${TEST_DIR}/none"

    # ImageMagick 6: only the legacy tools
    printf '#!/bin/bash\necho "convert $*"\n'  > "${TEST_DIR}/im6/convert"
    printf '#!/bin/bash\necho "identify $*"\n' > "${TEST_DIR}/im6/identify"

    # ImageMagick 7: unified "magick" (the legacy tools may still exist, but must not be used)
    printf '#!/bin/bash\necho "magick $*"\n'   > "${TEST_DIR}/im7/magick"
    printf '#!/bin/bash\necho "convert $*"\n'  > "${TEST_DIR}/im7/convert"
    printf '#!/bin/bash\necho "identify $*"\n' > "${TEST_DIR}/im7/identify"

    chmod +x "${TEST_DIR}"/im6/* "${TEST_DIR}"/im7/*
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function tear_down()
{
    rm -rf -- "${TEST_DIR}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_imagemagick_assert_installed()
{
    local exit_code=0
    local output

    # ImageMagick 6 (legacy tools only)
    PATH="${TEST_DIR}/im6" _imagemagick_assert_installed || exit_code=$?
    assert_same "0" "${exit_code}"

    # ImageMagick 7
    exit_code=0
    PATH="${TEST_DIR}/im7" _imagemagick_assert_installed || exit_code=$?
    assert_same "0" "${exit_code}"

    # only "magick" is enough
    rm "${TEST_DIR}/im7/convert" "${TEST_DIR}/im7/identify"
    exit_code=0
    PATH="${TEST_DIR}/im7" _imagemagick_assert_installed || exit_code=$?
    assert_same "0" "${exit_code}"

    # nothing installed
    exit_code=0
    output="$(PATH="${TEST_DIR}/none" _imagemagick_assert_installed 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_contains "ImageMagick is not installed" "${output}"

    # "convert" without "identify"
    rm "${TEST_DIR}/im6/identify"
    exit_code=0
    output="$(PATH="${TEST_DIR}/im6" _imagemagick_assert_installed 2>&1)" || exit_code=$?
    assert_same "1" "${exit_code}"
    assert_contains "ImageMagick is not installed" "${output}"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_imagemagick_convert()
{
    # ImageMagick 6 uses "convert"
    assert_same "convert in.png out.pdf" "$(PATH="${TEST_DIR}/im6" _imagemagick_convert in.png out.pdf)"

    # ImageMagick 7 uses "magick", even if "convert" still exists
    assert_same "magick in.png out.pdf" "$(PATH="${TEST_DIR}/im7" _imagemagick_convert in.png out.pdf)"
}

# /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function test_imagemagick_identify()
{
    # ImageMagick 6 uses "identify"
    assert_same "identify -format %w in.pdf" "$(PATH="${TEST_DIR}/im6" _imagemagick_identify -format %w in.pdf)"

    # ImageMagick 7 uses "magick identify", even if "identify" still exists
    assert_same "magick identify -format %w in.pdf" "$(PATH="${TEST_DIR}/im7" _imagemagick_identify -format %w in.pdf)"
}
