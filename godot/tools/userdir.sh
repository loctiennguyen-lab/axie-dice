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

# ---------------------------------------------------------------------------------------------
# Cô lập user dir cho MỌI lần chạy Godot qua with_lock.sh / run_tests.sh (19/10).
# Cây chính không có override.cfg nên trước đây test chạy trên user dir THẬT "Axie Dice" (cùng thư mục
# với bản desktop đã cài) và runner trả snapshot đè lên save Liam đang chơi. Giờ: nếu project chưa có
# user dir riêng, dùng tên cố định AxieDice-test-<tên thư mục repo> và with_lock.sh ghi một
# godot/override.cfg TẠM (có dấu $AXIE_TEMP_OVERRIDE_MARK) cho đúng lần chạy đó, xoá khi xong.
# (Godot 4.7 không có cờ dòng lệnh đặt project setting; override.cfg cạnh project.godot là đường duy nhất.)
# Tắt có chủ đích (vd chơi thử bằng save thật từ editor): AXIE_REAL_USERDIR=1.
#
# Dùng: axie_effective_userdir <godot/>  -> như axie_resolve_userdir, nhưng đặt thêm
#   AXIE_NEED_TEMP_OVERRIDE=1 khi phải ghi override.cfg tạm. Trả 1 nếu không xác định được.
AXIE_TEMP_OVERRIDE_MARK="; axie-temp-override (do godot/tools/with_lock.sh ghi, tự xoá, không commit, không export)"
axie_effective_userdir() {
  local proj="$1" cfg="$1/override.cfg" real name base repo
  AXIE_NEED_TEMP_OVERRIDE=0
  axie_resolve_userdir "$proj" || return 1
  real="$AXIE_USERDIR"
  # Đã có user dir riêng (override.cfg của worktree, hoặc override tạm còn sót): giữ nguyên.
  if [[ "$real" != */app_userdata/* ]]; then
    # override tạm còn sót từ lần bị SIGKILL: nhận lại để lần này xoá nó.
    if [[ -f "$cfg" ]] && grep -qF "axie-temp-override" "$cfg"; then
      AXIE_TEMP_OVERRIDE_NAME="$(sed -n 's/^config\/custom_user_dir_name="\(.*\)"$/\1/p' "$cfg" | head -1)"
      AXIE_NEED_TEMP_OVERRIDE=1
    fi
    return 0
  fi
  [[ "${AXIE_REAL_USERDIR:-}" == 1 ]] && return 0
  if [[ -f "$cfg" ]] && ! grep -qF "axie-temp-override" "$cfg"; then
    echo "userdir: $cfg có sẵn nhưng không đặt user dir riêng; sửa tay hoặc xoá, tôi không ghi đè." >&2
    return 1
  fi
  repo="$(basename "$(cd "$proj/.." && pwd -P)")"
  name="AxieDice-test-$(printf '%s' "$repo" | tr -c 'A-Za-z0-9._-' '_')"
  if [[ "$(uname)" == Darwin ]]; then base="$HOME/Library/Application Support"; else base="${XDG_DATA_HOME:-$HOME/.local/share}"; fi
  AXIE_USERDIR="$base/$name"
  AXIE_LOCK_DEFAULT="$HOME/Library/Caches/axie-dice-godot-$name.lock"
  AXIE_TEMP_OVERRIDE_NAME="$name"
  AXIE_NEED_TEMP_OVERRIDE=1
}

# Ghi override.cfg tạm nếu axie_effective_userdir báo cần. Gọi SAU khi đã giữ khoá.
axie_write_temp_override() {
  local proj="$1"
  [[ "${AXIE_NEED_TEMP_OVERRIDE:-0}" == 1 ]] || return 0
  printf '%s\n[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="%s"\n' \
    "$AXIE_TEMP_OVERRIDE_MARK" "$AXIE_TEMP_OVERRIDE_NAME" > "$proj/override.cfg.tmp.$$" \
    && mv "$proj/override.cfg.tmp.$$" "$proj/override.cfg"
}
axie_remove_temp_override() {
  local proj="$1"
  [[ "${AXIE_NEED_TEMP_OVERRIDE:-0}" == 1 ]] || return 0
  if grep -qF "axie-temp-override" "$proj/override.cfg" 2>/dev/null; then rm -f "$proj/override.cfg"; fi
}
