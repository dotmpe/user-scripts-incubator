#!/bin/sh


github_lib_load()
{
  test -n "${STATUSDIR_ROOT-}" || STATUSDIR_ROOT=$HOME/.statusdir/
  test -n "${UCONFDIR-}" || UCONFDIR=$HOME/.conf
  test -n "${UCACHEDIR-}" || UCACHEDIR=$HOME/.cache

  gh_cache=$UCACHEDIR/github-lib

  # gh_repo_list_spec=${STATUSDIR_ROOT}tree/github/repos/\$username.list
  gh_repo_lists=${STATUSDIR_ROOT}tree/github/repos
}

github_lib_init()
{
  test -d "$gh_cache" || mkdir -p "$gh_cache"
  test -d "$gh_repo_lists" || mkdir -p "$gh_repo_lists"

  true "${HTD_GIT_REMOTE:="$NS_NAME"}"
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
