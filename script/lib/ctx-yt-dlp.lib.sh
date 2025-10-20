ctx_yt_dlp_lib__load ()
{
  lib_require stattab class-uc uc-class args &&
  lib_init class-uc std-uc &&
  class_init User/Context || return

  local yt_dlp_conf=${yt_dlp_conf:-yt-dlp-uc.tab}
  if_ok "${YT_DLP_CONF:=$(out_fmt= statusdir_lookup ${yt_dlp_conf:?} index)}" ||
    $LOG alert :stattab "Expected yt-dlp config" "E$?:$yt_dlp_conf" $? ||
      return
}

ctx_yt_dlp_lib__init ()
{
  test -z "${ctx_yt_dlp_lib_init-}" || return $_
  lib_require urlstat-class || return
}

# Handler for stattab-data-list reader
# XXX: this only does YouTube URL's
ctx_yt_dlp__downloads__fetch_infos ()
{
  local url lk=:@yt-dlp:downloads:update
  test "${stb_data:0:1}" = "#" && {
    stderr echo "DIRECTIVE: $stb_data stat=$stb_stat rest=$stb_rest"
    return
  }

  local url="$stb_data" yt_{id,mi,fbn,fext,tt,td,tbr,fps,vres,tl,fn,fp}
  url_yt_dlp "$url"
}

ctx_yt_dlp__downloads__update ()
{
  bytes=$(filesize "$yt_fp") &&
  yt_cat=$(jq -r '.categories[]' < "$yt_mi") || return
  yt_cat="${yt_cat:+${yt_cat//$'\n'/,}}"
  #yt_tags=$(jq -r '.tags[]' < "$yt_mi")
  #yt_tags="${yt_tags:+${yt_tags//$'\n'/,}}"

  if_ok "$(date_id $(date --iso=sec))" || return
  : "$_ - yt:$yt_id:"
  : "$_${Playlist:+ playlist:$Playlist}"
  : "$_${yt_cat:+ cat:$yt_cat}"
  : "$_${yt_tt:+ \`$yt_tt\`}"
  : "$_${yt_td:+ [$yt_td]}"
  : "$_${yt_vres:+ $yt_vres}"
  if_ok "$_ $(readable_bytesize "$bytes")" || return
  : "$_${stb_rest:+ $stb_rest}"
  : "$_ @yt-dlp @URL"
  : "$_${Genre:+ genre:${Genre// /+}}"
  #: "$_${yt_tags:+ tags:${yt_tags// /+}}"
  : "$_${yt_cat:+ cat:${yt_cat// /+}}"

  echo "$_" >> "$UC_DLTAB" &&
  $LOG notice "$lk" "OK" "yt:$yt_id"

  #stderr echo "ctx_yt_dlp__downloads__update $# $*"

  #stderr declare -f class.Context
  #class.Context .field tag-refs "$stb_rest" &&
  #class.Context .load $ctx_tag_refs || return

  #TODO "@yt-dlp:downloads:update $(sys_callers)" || return

  local ctx_id
  Context.field id "$stb_rest" && {
    test -n "${ctx_id-}" || {
      echo Resource.id ""
    }
  }

  stderr echo stb_rest=$stb_rest
  stderr echo $ctx_urls.id_from_url "$url"
  #$ctx_urls.exists &&
  #$ctx_urls.fetch &&
}

url_yt_id ()
{
  local url=${1:?}
  : "${url#*"/watch?v="}"
  : "${_%%"&"*}"
  test "$url" != "$_" &&
  yt_id=${_} &&
  ((${#yt_id})) ||
    $LOG alert :url-yt "Unrecognized URL" "$url" 1
}

url_yt_dlp_mi ()
{
  yt_mi=.meta/info/yt--$yt_id.json
  [[ -s "$yt_mi" ]] && {
    true # >&2 echo "Found meta for ${url@Q}"
  } || {
    [[ ! -e "$yt_mi" ]] || rm "$yt_mi" || return
    >&2 echo "Fetching meta for ${url@Q}"
    #$LOG notice :url-yt "Fetching meta" "$url"
    yt-dlp ${yt_dlp_opts-} -j "$url" > "$yt_mi" || exit $?
  }
}

url_yt_dlp () # ~ <URL>
{
  local url=${1:?}
  url_yt_id "$url" || return

  # See if download exists already in some format, use that as base resource.
  # tl is tree-link, a symlink with simple name Id and some actual catalog name
  # as target.
  # XXX: should later track entries (table) but create symlinks for now
  : "$( shopt -s nullglob && echo .meta/tree/yt:$yt_id.* )" &&
  : "${_%% *}" &&
  yt_tl=$_ &&
  true || return

  #ctx_tab=$UC_DLTAB context --exists yt:$yt_id &&
  #  $LOG notice "$lk" "Found ..." "$_" && return

  # Download meta if we need to build a filename
  [[ ${yt_fp:+set} ]] || {
    [[ ${yt_tl:+set} && -e "${yt_tl-}" ]] && {
      #>&2 echo "Symlink exists $yt_tl"
      # Use symlink to get path instead
      yt_fp=$(realpath "${yt_tl:?}") || return
      yt_fn=${yt_fp##*/}
    } || {
      url_yt_dlp_mi &&
      url_yt_dl_readinfo &&
      url_yt_dl_path &&
      true || return
    }
  }

  [[ -s "${yt_fp-}" ]] && {
    ((ctx_yt_found+=1))
    return
    #stderr echo "Found $_ln/- ($ctx_yt_found) [#$yt_id] '$yt_fn'"
  } || {
    ((ctx_yt_pend+=1))
    #stderr echo TODO $yt_id $yt_fn
  }

  : "${yt_cat:-yt-dlp}"

  # remove empty
  [[ ! -e "$yt_fp" ]] || rm "$yt_fp" || return

  # put data at cat dir
  $LOG notice : "Downloading" "$yt_fp"
  yt-dlp ${yt_dlp_opts-} -P "$yt_cat" -o "$yt_fn" "$url" || exit $?

  # Updated/create symlink
  [[ ! -h "$yt_tl" ]] || {
    test "$_" = "../../$yt_fp" || rm -v "$yt_tl"
  }
  [[ -h "$yt_tl" ]] ||
    ln -vs "../../$yt_fp" "$yt_tl" || return

  $LOG notice : "Done" "$url"
  exit
}

url_yt_dl_readinfo ()
{
  if_ok "$(< "$yt_mi" \
      jq -r .filename,.ext,.title,.duration_string,.tbr,.fps,.resolution
    )" &&
  <<< "$_" lines_vars yt_fbn yt_fext yt_tt yt_td yt_tbr yt_fps yt_vres ||
    return

  # XXX: The filename field is probably more sanitized for uses as filename than title/fulltitle or is that optimistic
  : "${yt_fbn%.$yt_fext}"
  : "${_%"[$yt_id]"}"
  : "${_%% }"
  yt_fbn=$_
}

url_yt_dl_path ()
{
  yt_tl=.meta/tree/yt:$yt_id.$yt_fext
  #yt_fn_old="$yt_tt [yt:$yt_id].$yt_fext"
  yt_fn="$yt_fbn [$yt_td yt:$yt_id ${yt_tbr}bps ${yt_fps}fps ${yt_vres}].$yt_fext"
  yt_fp="$yt_cat/$yt_fn"
}

# Id: us-inc ctx-yt-dlp.lib ex:ft=bash:
