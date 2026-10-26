# Hotfix (26/10/2026) — BUG-0003: Undo / tải giữa trận mất bonus G ascend/forge

- godot-port 721b9b8 (+ docs 7e6a7b8). Không bump RULES_VERSION (vẫn -v), không đổi Worker (baeeebf0), không migration.
- Suite `AXIE_RELEASE=1` 253/253 (thêm t_unit_g_oc_roundtrip, t_soak_verify).
- Web: pck md5 `742c9d4cc6e3ab41418f6350dbb25002` khớp; html/js/wasm khớp. Bản R-Atia ở `build/web-prev-ra/`.
- Desktop b1705 (7e6a7b8): check_export sạch, codesign ad-hoc ok, PE ok; b1696 lưu sang `downloads/old/` (sha OK) rồi đăng b1705; `/download` hiện b1705.
