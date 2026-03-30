#!/usr/bin/env bash
#
# Provisioning and project init helpers

usage()
{
  echo 'Usage:'
  echo '  ./tools/sh/parts/init.sh <function name>'
}
abort() { usage && exit 2; } # XXX: see CI/c-bail also




# Groups

default()
{
  true
}


# Main

case "$(basename -- "$0" .sh)" in
  -* ) ;; # No main regardless

  init )
      test "$(basename "$(dirname "$0")")/$(basename "$0")" = parts/init.sh ||
        exit 105 # Sanity

      set -euo pipefail
      : "${CWD:="$PWD"}"
      . "$CWD/tools/sh/parts/env-0-1-lib-sys.sh"
      . "$CWD/tools/sh/parts/env-0-src.sh"
      . "$CWD/tools/sh/parts/env-0.sh"
      #. "${ci_tools:="$CWD/tools/ci"}/env.sh"

      "$@"
    ;;
esac
# Sync: U-S:
