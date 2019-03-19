#!/bin/sh
# Pub/dist

# XXX: export publish_ts=$(epoch_microtime)
export publish_ts=$($gdate +%s.%N)
ci_stages="$ci_stages publish"

echo 'Travis test-result: '"$TRAVIS_TEST_RESULT"

ci_announce "Starting ci:publish"

# FIXME: pubish
lib_load git vc
#os-htd git-htd vc-htd

test -e /srv/scm-git-local || {
  sudo mkdir -vp /srv/scm-git-local/ || true
  sudo chown travis /srv/scm-git-local || true
}

#set -- "bvberkum/script-mpe"
#git_scm_find "$1" || {
#  git_scm_get "$SCM_VND" "$1" || return
#}


sh_include "report-times"


# Sync: U-S:
