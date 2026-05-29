#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_module_unload_after_filesystem_use SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

printf 'module unload payload\n' >"${MNT}/file.txt" || r4_fail_exit write SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_FAIL write_failed
cat "${MNT}/file.txt" >/dev/null || r4_fail_exit read SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_FAIL read_failed
sync; umount "${MNT}" || r4_fail_exit unmount SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_FAIL unmount_failed
if ! out=$(rmmod reiser4 2>&1); then FAILED_STAGE=rmmod; printf 'SMOKE_RMMOD_FAIL module_ref_stuck=1 error="%s"\n' "$(r4_quote_msg "${out}")"; exit 1; fi
lsmod | grep reiser4 >"${ARTIFACT_DIR}/lsmod-after-rmmod.txt" 2>&1 || true
r4_ktxnmgrd_alive && printf 'SMOKE_KTXNMGRD_STUCK\n' && r4_fail_exit ktxnmgrd SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_FAIL ktxnmgrd_alive
r4_entd_alive && printf 'SMOKE_ENTD_STUCK\n' && r4_fail_exit entd SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_FAIL entd_alive
RESULT=PASS
printf 'SMOKE_MODULE_UNLOAD_AFTER_FILESYSTEM_USE_PASS\n'
