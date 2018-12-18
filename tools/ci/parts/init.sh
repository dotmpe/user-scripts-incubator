#!/bin/ash
# See .travis.yml

export ci_init_ts=$($gdate +"%s.%N")

$LOG note "" "Entry for CI pre-install / init phase"

$LOG note "" "PWD: $(pwd && pwd -P)"
$LOG note "" "Whoami: $( whoami )"
$LOG note "" "CI Env:"
{ env | grep -i 'shippable\|travis\|ci' | sed 's/^/	/' >&2; } || true

#$LOG note "$scriptname" "Build Env:"
#build_params | sed 's/^/	/' >&2

$LOG note "" "Verbosity: $verbosity"

$LOG note "" "Checking for Github Token..."
test -n "$GITHUB_TOKEN" ||
  $LOG error "$scriptname" "Github token expected for Travis login" "" 1

echo '---------- Check for sane GIT state'

GIT_COMMIT="$(git rev-parse HEAD)"
test "$GIT_COMMIT" = "$TRAVIS_COMMIT" || {

  # For Sanity: Travis won't complain if you accidentally
  # cache the checkout, but this should:
  git reset --hard $TRAVIS_COMMIT || {
    echo '---------- git reset:'
    env | grep -i Travis
    git status
    $LOG error ci:build "Unexpected checkout $GIT_COMMIT" "" 1
    return 1
  }
}


$LOG note "$scriptname" "GIT version: $GIT_DESCRIBE"

export PATH=$PATH:$HOME/.basher/bin:$HOME/.basher/cellar/bin

# Basicly if these don't run dont bother with anything,
# But cannot abort/skip a Travis build without failure, can they?

# This is also like the classic software ./configure.sh stage.

test -z "$BUILD_ID" || {
  test ! -d build || {
    rm -rf build
    $LOG note "$scriptname" "Cleaned build/"
  }
  mkdir -vp build
}

( mkdir -vp ~/.local && cd ~/.local/ && mkdir -vp  bin lib share )
mkdir ~/build/local

not_trueish "$SHIPPABLE" || {
  mkdir -vp shippable/{testresults,codecoverage}
  test -d shippable/codecoverage
}

fnmatch "* basename-reg *" " $TEST_SPECS " && {
  test -e ~/.basename-reg.yaml ||
    cp basename-reg.yaml ~/.basename-reg.yaml
}

for x in composer.lock .Gemfile.lock
do
  test -e .htd/$x || continue
  rsync -avzui .htd/$x $x
done

echo '---------- Finished CI setup'
echo "Travis Branch: $TRAVIS_BRANCH"
echo "Travis Commit: $TRAVIS_COMMIT"
echo "Travis Commit Range: $TRAVIS_COMMIT_RANGE"
# TODO: gitflow comparison/merge base
#vcflow-upstreams $TRAVIS_BRANCH
# set env and output warning if we're behind
#vcflow-downstreams
# similar.
echo
echo "User Conf: $(cd ~/.conf && git describe --always)" || true
echo "User Composer: $(cd ~/.local/composer && git describe --always)" || true
echo "User Bin: $(cd ~/bin && git describe --always)" || true
echo "User static lib: $(find ~/lib )" || true
echo
echo '---------- Listing user checkouts'
for x in $HOME/build/*/
do
    test -e $x/.git && {
        echo "$x at GIT $( cd $x && git describe --always )"
        continue

    } || {
        for y in $x/*/
        do
            test -e $y/.git &&
                echo "$y at GIT $( cd $y && git describe --always )" ||
                echo "Unkown $y"
        done
    }
done
echo
$LOG note "$scriptname" "ci/parts/init Done"
echo '---------- Starting build'
# Id: script-mpe/0.0.4-dev tools/ci/parts/init.sh
