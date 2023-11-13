ctx_yt_dlp__downloads__update ()
{
  local url dirdef=${DEF_DIR:-yt-dlp} lk=:@yt-dlp:downloads:update
  test "${stb_data:0:1}" = "#" && {
    stderr echo "$stb_data stat=$stb_stat rest=$stb_rest"
    return
  }
  local url="$stb_data" yt_{id,mi,fbn,fext,tt,td,tbr,fps,vres,tl,fn,fp}
  url_yt_id "$url" &&
  ctx_tab=$UC_DLTAB context --exists yt:$yt_id &&
    $LOG notice "$lk" "Found ..." "$_" && return

  url_yt_dlp "$url" || return
  test -n "${yt_fp-}" || {
    yt_fp=$(realpath "${yt_tl:?}") &&
    url_yt_dlp_mi &&
    url_yt_dl_fetch ||
      return
  }

  local dir=${Dir:-${dirdef-}}
  bytes=$(filesize "$yt_fp") &&
  yt_cat=$(jq -r '.categories[]' < "$yt_mi") || return
  yt_cat="${yt_cat:+${yt_cat//$'\n'/,}}"
  #yt_tags=$(jq -r '.tags[]' < "$yt_mi")
  #yt_tags="${yt_tags:+${yt_tags//$'\n'/,}}"

  if_ok "$(date_id $(date --iso=sec))" || return
  : "$_ - yt:$yt_id:"
  : "$_${Playlist:+ playlist:$Playlist}"
  : "$_${dir:+ dir:$dir}"
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
}

url_yt_id ()
{
  local url=${1:?}
  : "${url#*"watch?v="}"
  : "${_%%&*}"
  yt_id=$_
  test "$url" != "$yt_id" ||
    $LOG alert :url-yt "Unrecognized URL" "$url" 1 || return
}

url_yt_dlp_mi ()
{
  yt_mi=.meta/info/yt--$yt_id.json
  test -s "$yt_mi" || {
    test ! -e "$yt_mi" || rm "$yt_mi" || return
    $LOG debug :url-yt "Fetching meta" "$url"
    yt-dlp -j "$url" > "$yt_mi" || exit $?
  }
}

url_yt_dlp () # ~ <URL>
{
  local url=${1:?} dirdef=${DEF_DIR:-yt-dlp}
  url_yt_id "$url" &&
  url_yt_dlp_mi

  # XXX: should later track entries (table) but create symlinks for now
  local x
  for x in .meta/tree/yt:$yt_id.*
  do
    test -e "$x" && {
      test -s "$x" || break
      yt_tl=$x
      return # Return on first existing
    }
  done

  url_yt_dl_fetch &&
  url_yt_dlp_path || return

  set -- .meta/tree
  test -n "${Dir-}" && set -- "$Dir"
  mkdir -vp "$@"

  test -s "$yt_fp" || {
    test ! -e "$yt_fp" || rm "$yt_fp" || return
    $LOG info : "Downloading" "$yt_fp"
    yt-dlp -P "${Dir:-$dirdef}" -o "$yt_fn" "$url" || exit $?
  }

  test ! -h "$yt_tl" || {
    test "$_" = "../../$yt_fp" || rm -v "$yt_tl"
  }
  test -h "$yt_tl" ||
    ln -vs "../../$yt_fp" "$yt_tl" || return

  $LOG notice : "Done" "$url"
}

url_yt_dl_fetch ()
{
  lines_vars yt_fbn yt_fext yt_tt yt_td yt_tbr yt_fps yt_vres \
    <<< "$(< "$yt_mi" \
      jq -r .filename,.ext,.title,.duration_string,.tbr,.fps,.resolution)"

  # The filename is probably more sanitized for uses as filename then title/fulltitle
  : "${yt_fbn%.$yt_fext}"
  : "${_%"[$yt_id]"}"
  : "${_%% }"
  yt_fbn=$_
}

url_yt_dlp_path ()
{
  #yt_of="%(title)s [%(id)s].%(ext)s"

  yt_tl=.meta/tree/yt:$yt_id.$yt_fext
  yt_fn_old="$yt_tt [yt:$yt_id].$yt_fext"
  yt_fn="$yt_fbn [$yt_td yt:$yt_id ${yt_tbr}bps ${yt_fps}fps ${yt_vres}].$yt_fext"
  yt_fp="${Dir:-${dirdef:?}}/$yt_fn"

}
