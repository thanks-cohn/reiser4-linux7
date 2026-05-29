#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_fsck_after_clean_unmount SMOKE_FSCK_AFTER_CLEAN_UNMOUNT
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_FSCK_AFTER_CLEAN_UNMOUNT_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

printf 'fsck payload\n' >"${MNT}/file.txt" || r4_fail_exit write SMOKE_FSCK_AFTER_CLEAN_UNMOUNT_FAIL write_failed
sync; umount "${MNT}" || r4_fail_exit unmount SMOKE_FSCK_AFTER_CLEAN_UNMOUNT_FAIL unmount_failed
command -v fsck.reiser4 >/dev/null 2>&1 || r4_fail_exit preflight SMOKE_FSCK_AFTER_CLEAN_UNMOUNT_FAIL missing_fsck_reiser4
r4_log FSCK_VERSION "version=\"$(fsck.reiser4 -V 2>&1 | head -1 || true)\""
set +e
fsck.reiser4 -y "${IMAGE}" >"${ARTIFACT_DIR}/fsck.log" 2>&1
fsck_rc=$?
set -u
r4_log FSCK_EXIT "exit_code=${fsck_rc}"
if [[ ${fsck_rc} -gt 1 ]]; then r4_fail_exit fsck SMOKE_FSCK_AFTER_CLEAN_UNMOUNT_FAIL "fsck exit ${fsck_rc}"; fi
RESULT=PASS
printf 'SMOKE_FSCK_AFTER_CLEAN_UNMOUNT_PASS exit_code=%s\n' "${fsck_rc}"
