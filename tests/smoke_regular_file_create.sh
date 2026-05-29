#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_regular_file_create SMOKE_REGULAR_FILE_CREATE
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_FILE_CREATE_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

FILE=${MNT}/regular-file.txt
touch "${FILE}" >"${ARTIFACT_DIR}/file-create.log" 2>&1 || r4_fail_exit file_create SMOKE_FILE_CREATE_FAIL "$(cat "${ARTIFACT_DIR}/file-create.log")"
stat "${FILE}" >"${ARTIFACT_DIR}/file-stat.txt" 2>&1 || true
inode=$(stat -c '%i' "${FILE}" 2>/dev/null || echo unknown)
r4_log FILE_CREATE "path=${FILE}" "inode=${inode}"
RESULT=PASS
printf 'SMOKE_FILE_CREATE_PASS path="%s" inode=%s\n' "${FILE}" "${inode}"
