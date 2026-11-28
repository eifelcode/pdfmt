#!/usr/bin/env bash
# =====================================================================================================================
# Script: ci-local.sh
#
# Description:
# Runs `make test` in a fresh Ubuntu container with the same packages as the Linux job of the CI
# (.github/workflows/snapshot.yaml). The tests run as a normal user (like on the GitHub runner), the repository is
# copied into the container, so nothing is written into your working directory.
#
# Only Linux can be reproduced this way; the macOS job of the CI can not.
#
# Requirements: Docker (running)
#
# Usage:
# tools/ci-local.sh [image]
#
# Examples:
# tools/ci-local.sh                # ubuntu:latest (what "ubuntu-latest" is closest to)
# tools/ci-local.sh ubuntu:22.04   # older distribution (e.g. qpdf 10, ImageMagick 6)
# =====================================================================================================================
set -euo pipefail

function main()
{
    local -r image="${1:-ubuntu:latest}"
    local -r root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

    if ! command -v docker >/dev/null 2>&1; then
        echo "ERROR: docker is not installed" >&2
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "ERROR: the Docker daemon is not running" >&2
        return 1
    fi

    local bashunit_version
    bashunit_version="$(sed -n 's/^BASHUNIT_VERSION *= *//p' "${root_dir}/Makefile")"
    if [[ -z "${bashunit_version}" ]]; then
        echo "ERROR: could not read BASHUNIT_VERSION from the Makefile" >&2
        return 1
    fi

    echo "Image:    ${image}"
    echo "bashunit: ${bashunit_version}"
    echo

    docker run --rm \
        --platform linux/amd64 \
        -e "BASHUNIT_VERSION=${bashunit_version}" \
        -e "DEBIAN_FRONTEND=noninteractive" \
        -v "${root_dir}:/src:ro" \
        "${image}" \
        bash -euo pipefail -c '
            # Packages of the Linux job in .github/workflows/snapshot.yaml (+ tools the runner image already has)
            apt-get update -qq
            apt-get install -y -qq \
                make curl ca-certificates \
                shellcheck ocrmypdf pdftk qpdf jq poppler-utils sane-utils imagemagick >/dev/null

            # Like the GitHub runner: a normal user instead of root (root ignores file permissions)
            useradd -m -s /bin/bash runner
            mkdir /home/runner/work
            tar -C /src --exclude=./dist --exclude=./lib/bashunit --exclude=./.git -cf - . | tar -C /home/runner/work -xf -
            chown -R runner:runner /home/runner/work

            su runner -c "
                set -euo pipefail
                cd /home/runner/work
                export BASHUNIT_VERIFY_CHECKSUM=true
                curl -fsSL --retry 3 -o /tmp/install-bashunit.sh https://bashunit.com/install.sh
                bash /tmp/install-bashunit.sh \"\${BASHUNIT_VERSION}\"
                make test
            "
        '
}

main "$@"
