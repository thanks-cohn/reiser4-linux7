#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_module_lifecycle SMOKE_MODULE_LIFECYCLE
trap r4_finish_test EXIT
r4_require_root || r4_fail_exit preflight SMOKE_MODULE_LIFECYCLE_FAIL root_required
[[ -e reiser4.ko ]] || r4_fail_exit preflight SMOKE_MODULE_LIFECYCLE_FAIL missing_reiser4_ko
if r4_module_loaded; then R4_SKIP_RMMOD=1; r4_fail_exit preflight SMOKE_INSMOD_FAIL 'module already loaded; clean boot/state required'; fi
insmod ./reiser4.ko >"${ARTIFACT_DIR}/insmod.log" 2>&1 || r4_fail_exit insmod SMOKE_INSMOD_FAIL "$(cat "${ARTIFACT_DIR}/insmod.log")"
printf 'SMOKE_INSMOD_PASS\n'
grep -q reiser4 /proc/filesystems || r4_fail_exit proc_filesystems SMOKE_PROC_FILESYSTEMS_FAIL reiser4_missing
printf 'SMOKE_PROC_FILESYSTEMS_PASS\n'
rmmod reiser4 >"${ARTIFACT_DIR}/rmmod.log" 2>&1 || r4_fail_exit rmmod SMOKE_RMMOD_FAIL "$(cat "${ARTIFACT_DIR}/rmmod.log")"
printf 'SMOKE_RMMOD_PASS\n'
RESULT=PASS
printf 'SMOKE_MODULE_LIFECYCLE_PASS\n'
