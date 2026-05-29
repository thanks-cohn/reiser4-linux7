#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_mount_root_stat_unmount SMOKE_MOUNT_ROOT_STAT_UNMOUNT
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_MOUNT_ROOT_STAT_UNMOUNT_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

findmnt "${MNT}" >"${ARTIFACT_DIR}/findmnt.txt" 2>&1 || true
stat "${MNT}" >"${ARTIFACT_DIR}/root-stat.txt" 2>&1 || r4_fail_exit root_stat SMOKE_ROOT_STAT_FAIL "$(cat "${ARTIFACT_DIR}/root-stat.txt")"
printf 'SMOKE_ROOT_STAT_PASS\n'
umount "${MNT}" >"${ARTIFACT_DIR}/umount.log" 2>&1 || r4_fail_exit unmount SMOKE_UNMOUNT_FAIL "$(cat "${ARTIFACT_DIR}/umount.log")"
printf 'SMOKE_UNMOUNT_PASS\n'
rmmod reiser4 >"${ARTIFACT_DIR}/rmmod.log" 2>&1 || r4_fail_exit rmmod SMOKE_RMMOD_FAIL "$(cat "${ARTIFACT_DIR}/rmmod.log")"
printf 'SMOKE_RMMOD_PASS\n'
RESULT=PASS
printf 'SMOKE_MOUNT_ROOT_STAT_UNMOUNT_PASS\n'
