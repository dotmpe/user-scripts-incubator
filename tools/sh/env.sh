#!/bin/ash

: "${script_env_init:=$PWD/tools/sh/parts/env.sh}"
. "$script_env_init"

. $script_util/parts/env-std.sh
. $script_util/parts/env-src.sh
. $script_util/parts/env-test-bats.sh
