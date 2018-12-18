#!/bin/ash
# See .travis.yml

export_stage script && announce_stage

. $PWD/tools/git-hooks/pre-commit

. $ci_util/deinit.sh
