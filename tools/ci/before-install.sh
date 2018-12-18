#!/bin/sh

echo '--------------------'
git status && git describe --always
echo '--------------------'
find ~/.travis || true
echo '--------------------'
echo "Terminal: $TERM"
echo "Shell: $SHELL"
echo "Shell-Options: $-"
echo "Shell-Level: $SHLVL"

. ./tools/ci/util.sh

export_stage before-install before_install
  # Leave loading env parts to sh/env, but sets may diverge..
  # $script_util/parts/env-*.sh
  # $ci_util/parts/env-*.sh

script_env_init=tools/ci/parts/env.sh . ./tools/sh/env.sh

. $ci_util/parts/init.sh

. $ci_util/deinit.sh
