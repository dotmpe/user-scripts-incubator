#!/usr/bin/env bash

$INIT_LOG "note" "" "Adding SCRIPTPATH" "$(dirname "${BASH_SOURCE[0]}")"
SCRIPTPATH="$SCRIPTPATH${SCRIPTPATH:+":"}$(dirname "${BASH_SOURCE[0]}")/script/lib"
