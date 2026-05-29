#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_regular_file_remount_verify SMOKE_REGULAR_FILE_REMOUNT_VERIFY
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_REGULAR_FILE_REMOUNT_VERIFY_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

FILE=${MNT}/remount-file.txt; PAYLOAD=${ARTIFACT_DIR}/payload.txt
printf 'remount verify payload\n' >"${PAYLOAD}"
cp "${PAYLOAD}" "${FILE}" || r4_fail_exit file_write SMOKE_FILE_REMOUNT_VERIFY_FAIL write_failed
sha_before=$(sha256sum "${PAYLOAD}" | awk '{print $1}')
sync
umount "${MNT}" || r4_fail_exit unmount SMOKE_FILE_REMOUNT_VERIFY_FAIL unmount_failed
mount -t reiser4 -o loop "${IMAGE}" "${MNT}" >"${ARTIFACT_DIR}/remount.log" 2>&1 || r4_fail_exit remount SMOKE_FILE_REMOUNT_VERIFY_FAIL "$(cat "${ARTIFACT_DIR}/remount.log")"
sha_after=$(sha256sum "${FILE}" | awk '{print $1}')
[[ ${sha_before} == "${sha_after}" ]] || r4_fail_exit remount_verify SMOKE_FILE_REMOUNT_VERIFY_FAIL "sha mismatch before=${sha_before} after=${sha_after}"
r4_log REMOUNT_VERIFY "sha256_before=${sha_before}" "sha256_after=${sha_after}"
RESULT=PASS
printf 'SMOKE_FILE_REMOUNT_VERIFY_PASS\n'
