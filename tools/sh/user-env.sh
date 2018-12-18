#!/bin/sh

test -n "$UCACHE" || UCACHE=$HOME/.cache/local
test -d "$UCACHE/user-env" || mkdir -p "$UCACHE/user-env"

# XXX: not sure where/how/why to put this but keeping a cache to capture
# pipeline result value
ENV_D_SCRIPTPATH=$UCACHE/user-env/$$-SCRIPTPATH.txt

# Pipe interesting paths to SCRIPTPATH-builder
{
  for basedir in ~/project $HOME/build/bvberkum $HOME/build/user-tools $HOME/lib/sh
  do
    for supportlib in script-mpe user-scripts user-scripts-support user-conf
    do
      test -d "$basedir/$supportlib" || continue
      echo "$basedir/$supportlib"
    done
  done
} | while read path
do
  for base in /script/lib /commands /contexts $sh_src_base
  do
    test -d "$path$base" || continue
    echo "$path$base"
  done
done | tr '\n' ':' | sed 's/:$/\
/' | {

  read SCRIPTPATH

  # FIXME: script-path legacy, soem for cleanup
  test -d $HOME/bin && SCRIPTPATH=$SCRIPTPATH:$HOME/bin
  test -d $HOME/lib/sh && SCRIPTPATH=$SCRIPTPATH:$HOME/lib/sh
  test -d $HOME/.conf && SCRIPTPATH=$SCRIPTPATH:$HOME/.conf/script

  echo $SCRIPTPATH >"$ENV_D_SCRIPTPATH"
}
read SCRIPTPATH_ <"$ENV_D_SCRIPTPATH"
rm "$ENV_D_SCRIPTPATH"
unset ENV_D_SCRIPTPATH

test -n "$SCRIPTPATH" && {

  SCRIPTPATH=$SCRIPTPATH_:$SCRIPTPATH
} || {

  SCRIPTPATH=$SCRIPTPATH_
}
unset SCRIPTPATH_
export SCRIPTPATH

$LOG debug user-env "Script-Path:" "$SCRIPTPATH"

# Id: user-scripts-incubator/0.0.0-dev tools/sh/user-env.sh
