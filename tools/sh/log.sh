#!/bin/sh

# Logger: arg-to-colored ansi line output
# Usage:
#   log.sh [Line-Type] [Header] [Msg] [Ctx] [Exit]


test -z "$verbosity" && {
    test -n "$DEBUG" && verbosity=7 || verbosity=6
}

logger_stderr_num() # Level-Name
{
  case "$1" in
      emerg ) echo 1 ;;
      crit  ) echo 2 ;;
      error ) echo 3 ;;
      warn* ) echo 4 ;;
      note|notice  ) echo 5 ;;
      info  ) echo 6 ;;
      debug ) echo 7 ;;
      * ) return 1 ;;
  esac
}

__log() # [Line-Type] [Header] [Msg] [Ctx] [Exit]
{
  test -n "$2" || {
    test -n "$scriptname" && set -- "$1" "$scriptname" "$3" "$4" "$5"
  }

  lvl=$(logger_stderr_num "$1")
  test -z "$lvl" || {
    test $verbosity -ge $lvl || {
      test -n "$5" && exit $5 || {
        exit 0
      }
    }
  }

  indent=""

  case "$1" in

    emerg|crit| error|warn|warning )
        prefix="[$2]"
      ;;

    note|info|debug )
        prefix=" $2:"
      ;;

    ok|pass|passed )
        prefix="[$2] OK"
        test -z "$3" || prefix="$prefix:"
      ;;

    not[_-]ok|nok|fail|failed )
        prefix="[$2] Failed"
        test -z "$3" || prefix="$prefix:"
      ;;

    file[_-]ok|file[_-]pass|file[_-]passed )
        prefix="<$2> OK"
        test -z "$3" || prefix="$prefix:"
      ;;

    file[_-]not[_-]ok|file[_-]nok|file[_-]fail|file[_-]failed )
        prefix="<$2> Failed"
        test -z "$3" || prefix="$prefix:"
      ;;

  esac

  test -z "$4" && suffix="" || suffix="$4"

  test -n "$suffix" && {
    printf "%s%s %s <%s>\n" "$indent" "$prefix" "$3" "$suffix" >&2
  } || {
    printf "%s%s %s\n" "$indent" "$prefix" "$3" >&2
  }

  test -z "$5" || exit $5
}


# Start in stream mode or print one line and exit.
if test "$1" = '-'
then
  export IFS="	"; # tab-separated fields for $inp
  while read lt p m c s;
  do
    __log "$lt" "$p" "$m" "$c" "$s";
  done
else
  case "$1" in
    demo )
        set -- demo "Test message line" "123"
        __log "error" "$@"
        __log "warn" "$@"
        __log "note" "$@"
        __log "info" "$@"
        __log "debug" "$@"
        __log "ok" "$@"
        __log "fail" "$@"
      ;;
    * )
        __log "$1" "$2" "$3" "$4" "$5"
      ;;
  esac
fi
