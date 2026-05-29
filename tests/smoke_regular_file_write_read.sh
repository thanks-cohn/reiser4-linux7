#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_regular_file_write_read SMOKE_REGULAR_FILE_WRITE_READ
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_REGULAR_FILE_WRITE_READ_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

FILE=${MNT}/rw-file.txt; PAYLOAD=${ARTIFACT_DIR}/payload.bin; READBACK=${ARTIFACT_DIR}/readback.bin
printf 'Reiser4-NX V3 write/read payload %s\n' "$(date -u +%s)" >"${PAYLOAD}"
sha_before=$(sha256sum "${PAYLOAD}" | awk '{print $1}')
cp "${PAYLOAD}" "${FILE}" >"${ARTIFACT_DIR}/file-write.log" 2>&1 || r4_fail_exit file_write SMOKE_FILE_WRITE_FAIL "$(cat "${ARTIFACT_DIR}/file-write.log")"
sync >"${ARTIFACT_DIR}/sync.log" 2>&1 || r4_fail_exit sync SMOKE_FILE_WRITE_FAIL sync_failed
printf 'SMOKE_FILE_WRITE_PASS sha256=%s\n' "${sha_before}"
cat "${FILE}" >"${READBACK}" 2>"${ARTIFACT_DIR}/file-read.err" || r4_fail_exit file_read SMOKE_FILE_READ_FAIL "$(cat "${ARTIFACT_DIR}/file-read.err")"
sha_after=$(sha256sum "${READBACK}" | awk '{print $1}')
[[ ${sha_before} == "${sha_after}" ]] || r4_fail_exit file_read SMOKE_FILE_READ_FAIL "sha mismatch before=${sha_before} after=${sha_after}"
r4_log FILE_RW "sha256_before=${sha_before}" "sha256_after=${sha_after}" "size=$(stat -c '%s' "${FILE}" 2>/dev/null || echo 0)"
printf 'SMOKE_FILE_READ_PASS sha256=%s\n' "${sha_after}"
RESULT=PASS
printf 'SMOKE_REGULAR_FILE_WRITE_READ_PASS\n'
