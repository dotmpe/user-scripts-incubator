#!/bin/sh


github_lib_load()
{
  test -n "${STATUSDIR_ROOT-}" || STATUSDIR_ROOT=$HOME/.statusdir/
  test -n "${UCONFDIR-}" || UCONFDIR=$HOME/.conf
  test -n "${UCACHEDIR-}" || UCACHEDIR=$HOME/.cache

  gh_cache=$UCACHEDIR/github-lib
  test -n "${gh_cache_expire-}" || gh_cache_expire=$_1DAY

  # XXX: gh_repo_list_spec=${STATUSDIR_ROOT}tree/github/repos/\$username.list
  gh_repo_lists=${STATUSDIR_ROOT}tree/github/repos
  gh_release_lists=${STATUSDIR_ROOT}tree/github/releases
}

github_lib_init()
{
  test -d "$gh_cache" || mkdir -p "$gh_cache"
  test -d "$gh_repo_lists" || mkdir -p "$gh_repo_lists"
  test -d "$gh_release_lists" || mkdir -p "$gh_release_lists"

  true "${HTD_GIT_REMOTE:="$NS_NAME"}"
}


github_release_list() # [Username] [Reponame]
{
  test -n "$1" || set -- "$NS_NAME" "$2"
  test -n "$2" || set -- "$1" "$APP_ID"
  test -n "$1" -a -n "$2" || return

  local cached=$gh_cache/$1/$2/releases.json list=$gh_release_lists/$1/$2.list

  local empty="$gh_release_lists/$1/$2.empty"

  { {
      test -e $empty && newer_than $empty $gh_cache_expire
    } || {
      test -s $cached && newer_than $cached $gh_cache_expire
    }
  } && {

    $LOG info github.lib "Cache up-to-date" "$cached @$gh_cache_expire"

  } || {

    test -d $gh_cache/$1/$2 || mkdir $gh_cache/$1/$2
    github-release info --user "$1" --repo "$2" -j >"$cached"

    $LOG info github.lib "Updated cache github project releases.json" "$cached"
    test -s "$cached" -o ! -e "$cached" || rm "$cached"
  }

  test -s "$cached" && {
    test "$cached" -nt "$list" || {
      github_release_query_names "$@" | tee "$list"
    }

  } || {

    test -e "$empty" || {
      mkdir -p "$gh_release_lists/$1" && touch "$empty"
    }
  }
}


github_release_query_names()
{
  test -n "${1-}" || set -- "$HTD_GIT_REMOTE" "$2"
  test -n "${2-}" || set -- "$1" "$APP_ID"
  test -n "$1" -a -n "$2" || return

  local cached=$gh_cache/$1/$2/releases.json

  test "null" = "$(jq -r '.Releases' $cached)" && {

    test "null" = "$(jq -r '.Tags' $cached)" && {

      $LOG warn "" "No tags or releases"

    } || jq -r '.Tags[] | .name' "$cached"

  } || jq -r '.Releases[] | .tag_name' "$cached"
}


github_repos_list() # [Username]
{
  test -n "${1-}" || set -- $HTD_GIT_REMOTE
  test -n "$1" || return

  local cached=$gh_cache/$1/repos.json list=$gh_repo_lists/$1.list

  { test -e $cached -a -s $cached && newer_than $cached $_1DAY
  } && std_info "Cached list <$cached $_1DAY>" || {

    URL="https://api.github.com/users/$1/repos"
    per_page=100

    test -d $gh_cache/$1 || mkdir $gh_cache/$1

    web_resolve_paged_json "$URL" per_page page >"$cached"|| return $?

    std_info "Updated cache github user-repos.json <$cached>"
  }

  test -e $list -a $list -nt $cached && {
    cat $list || return $?
  } || {
    jq -r 'to_entries[] as $r | $r.value.full_name' $cached | tee $list

    std_info "Updated list from new cache <$cached $list>"
  }

  note "$(count_lines "$list") (public) repositories listed for '$1' <$list>"
}
