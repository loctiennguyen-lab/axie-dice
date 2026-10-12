class_name DeviceTokens
extends RefCounted
## Desktop sign-in tokens ({access, refresh, expires_at, device_id}) kept in an encrypted file.
##
## DEBT (ADR-RNG 4.8 S6): the real home for these is the OS keychain (macOS Keychain, Windows
## Credential Manager), which needs a small GDExtension. Until that is assessed this is a file
## encrypted with a key derived from the machine id. That stops a casual copy of the file to
## another machine; it does NOT stop malware running as the same user. The server limits the damage:
## the access token lives 20 minutes, a refresh token only works for one device, and the device
## can be revoked from /auth/devices.
##
## Not part of the game save on purpose: tokens must not follow the player through cloud save.

const PATH := "user://device_tokens.dat"
const _SALT := "axiedice/device-tokens/v1"


static func _key() -> String:
	return (_SALT + OS.get_unique_id()).sha256_text()


static func save(tokens: Dictionary, path: String = PATH) -> bool:
	var f := FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, _key())
	if f == null:
		return false
	f.store_string(JSON.stringify(tokens))
	f.close()
	return true


## {} when there is no file, it cannot be decrypted (other machine) or it is malformed.
static func load_tokens(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open_encrypted_with_pass(path, FileAccess.READ, _key())
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


static func clear(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
