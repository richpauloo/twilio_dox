#!/bin/bash

## modified from https://github.com/rocker-org/rocker-versioned2/blob/master/scripts/install_verse.sh
## and truncated to only include libxml2-dev so that rvest will install
## basically building rocker/verse base image on top of rcoker/rstudio
## from scratch because rstudio image is the only one that has a working
## RStudio Server on Apple M1
set -e

## build ARGs
NCPUS=${NCPUS:--1}

# shellcheck source=/dev/null
source /etc/os-release

# always set this for scripts but don't declare as ENV..
export DEBIAN_FRONTEND=noninteractive

# a function to install apt packages only if they are not installed
function apt_install() {
    if ! dpkg -s "$@" >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            apt-get update
        fi
        apt-get install -y --no-install-recommends "$@"
    fi
}

apt_install libxml2-dev
