#!/usr/bin/env bash
# CI suite stage 1. See .travis.yml
set -ueo pipefail

: "${CWD:="$PWD"}"
: "${U_S:="$CWD"}" # No-Sync

echo "Sourcing env (I)" >&2
: "${ci_tools:="$CWD/tools/ci"}"
. "${ci_tools}/env.sh"

ci_stages="$ci_stages ci_env_1 sh_env_1"
ci_env_1_ts=$ci_env_ts sh_env_1_ts=$sh_env_ts sh_env_1_end_ts=$sh_env_end_ts

trap ci_cleanup EXIT

# Set timestamps for each stage start/end XXX: and stack
export_stage before-install before_install && announce_stage

# XXX: ${SUITE}
echo "Sourcing init parts" "$(suite_from_table "build.txt" Parts CI 1|tr '\n' ' ')" >&2
suite_source "build.txt" CI 1
test $SKIP_CI -eq 0 || exit 0

stage_id=before_install close_stage
set +euo pipefail
# Sync: U-S:
