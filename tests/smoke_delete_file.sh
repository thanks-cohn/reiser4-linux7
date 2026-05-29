#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_delete_file SMOKE_DELETE_FILE
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_DELETE_FILE_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

FILE=${MNT}/delete-me.txt
printf 'delete payload\n' >"${FILE}" || r4_fail_exit create SMOKE_DELETE_FILE_FAIL create_failed
rm "${FILE}" >"${ARTIFACT_DIR}/unlink.log" 2>&1 || r4_fail_exit unlink SMOKE_DELETE_FILE_FAIL "$(cat "${ARTIFACT_DIR}/unlink.log")"
sync
umount "${MNT}" || r4_fail_exit unmount SMOKE_DELETE_FILE_FAIL unmount_failed
mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_fail_exit remount SMOKE_DELETE_FILE_FAIL remount_failed
[[ ! -e ${FILE} ]] || r4_fail_exit remount_verify SMOKE_DELETE_FILE_FAIL file_reappeared
r4_log DELETE "unlink_result=0" "remount_verification=gone"
RESULT=PASS
printf 'SMOKE_DELETE_FILE_PASS\n'
