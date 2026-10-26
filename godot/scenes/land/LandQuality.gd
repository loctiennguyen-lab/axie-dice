class_name LandQuality
extends RefCounted
## LD-A 4: light mode for the web build (2 Axies instead of 5). Real shadows stay as they are for now.
static var force_light := -1   # tests: 0 = off, 1 = on, -1 = real platform


static func is_light() -> bool:
	if force_light >= 0:
		return force_light == 1
	return OS.has_feature("web")


## How many Axies walk the Land.
static func wanderers() -> int:
	return 2 if is_light() else 5
