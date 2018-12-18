#!/bin/ash

set -o pipefail
set -o errexit
set -o nounset

: "${script_util:=$PWD/tools/sh}"
: "${ci_util:=$PWD/tools/ci}"
export script_util ci_util
