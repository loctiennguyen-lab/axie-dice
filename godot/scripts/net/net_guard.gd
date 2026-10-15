class_name NetGuard
extends RefCounted
## Test-only switch: when AXIE_TEST_NO_NET=1 (set by run_tests.sh) every REAL socket / HTTP / curl
## entry point fails immediately, with the same shape it returns when offline. Injected fakes
## (Callables set by tests) are not affected: they never reach these entry points.

static func blocked() -> bool:
	return OS.get_environment("AXIE_TEST_NO_NET") == "1"
