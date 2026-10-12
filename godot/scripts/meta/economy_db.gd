extends Node
## Loader cho dữ liệu economy (L1 lane E). Contract: production/l1-interfaces.md §5.1.
## Autoload `EconomyDB` do làn I đăng ký; code trong scripts/meta/ gọi qua
## preload("res://scripts/meta/economy_db.gd") (hàm static) nên không phụ thuộc đăng ký autoload.
##
## 14/10: SKELETON — chưa có JSON, get_table trả {} và version trả 0.

const DATA_DIR := "res://assets/data/economy/"

## Đọc bảng `name` (tên file không đuôi, vd "gem"). {} nếu thiếu.
static func get_table(_name: String) -> Dictionary:
	return {}


## Số "version" ở đầu file; 0 nếu thiếu.
static func version(_name: String) -> int:
	return 0
