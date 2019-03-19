#!/bin/sh
sh_usr_env_="$_"


. "$script_util/parts/env-init-log.sh"
. "$script_util/parts/env-ucache.sh"


. "$script_util/parts/env-scriptpath.sh"


$INIT_LOG "debug" "user-env" "Script-Path:" "$SCRIPTPATH"

# Sync: U-S:
# Id: user-scripts-incubator/0.0.0-dev tools/sh/user-env.sh
