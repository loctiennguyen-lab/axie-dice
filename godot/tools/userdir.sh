# Được `source` bởi with_lock.sh và run_tests.sh. Suy ra thư mục user:// THẬT mà Godot sẽ dùng
# cho một project, và đường dẫn khoá tương ứng. Không chạy trực tiếp.
#
# Nếu <project>/override.cfg (KHÔNG track, chỉ có ở worktree của làn) đặt
#   config/use_custom_user_dir=true  và  config/custom_user_dir_name="<tên>"
# thì user:// nằm ở: mac    ~/Library/Application Support/<tên>
#                    linux  ${XDG_DATA_HOME:-~/.local/share}/<tên>
# và khoá riêng theo tên đó (các worktree không còn xếp hàng chung). Không có override.cfg
# (cây chính, save thật của Liam): app_userdata/<config/name> và khoá chung cũ, như trước.
#
# Dùng: axie_resolve_userdir <thư mục godot/>  -> đặt AXIE_USERDIR, AXIE_LOCK_DEFAULT
axie_resolve_userdir() {
  local proj="$1" cfg="$1/override.cfg" custom="" name="" base
  if [[ "$(uname)" == Darwin ]]; then
    base="$HOME/Library/Application Support"
  else
    base="${XDG_DATA_HOME:-$HOME/.local/share}"
  fi
  if [[ -f "$cfg" ]] && grep -Eq '^[[:space:]]*config/use_custom_user_dir[[:space:]]*=[[:space:]]*true' "$cfg"; then
    custom="$(sed -n 's/^[[:space:]]*config\/custom_user_dir_name[[:space:]]*=[[:space:]]*"\(.*\)".*$/\1/p' "$cfg" | head -1)"
  fi
  if [[ -n "$custom" ]]; then
    AXIE_USERDIR="$base/$custom"
    AXIE_LOCK_DEFAULT="$HOME/Library/Caches/axie-dice-godot-$(printf '%s' "$custom" | tr -c 'A-Za-z0-9._-' '_').lock"
    return 0
  fi
  name="$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$proj/project.godot" 2>/dev/null | head -1)"
  [[ -n "$name" ]] || return 1
  if [[ "$(uname)" == Darwin ]]; then
    AXIE_USERDIR="$base/Godot/app_userdata/$name"
  else
    AXIE_USERDIR="$base/godot/app_userdata/$name"
  fi
  AXIE_LOCK_DEFAULT="$HOME/Library/Caches/axie-dice-godot.lock"
}
