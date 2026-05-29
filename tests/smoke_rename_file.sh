#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_rename_file SMOKE_RENAME_FILE
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_RENAME_FILE_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

OLD=${MNT}/old-name.txt; NEW=${MNT}/new-name.txt
printf 'rename payload\n' >"${OLD}" || r4_fail_exit create SMOKE_RENAME_FILE_FAIL create_failed
mv "${OLD}" "${NEW}" >"${ARTIFACT_DIR}/rename.log" 2>&1 || r4_fail_exit rename SMOKE_RENAME_FILE_FAIL "$(cat "${ARTIFACT_DIR}/rename.log")"
[[ ! -e ${OLD} && -f ${NEW} ]] || r4_fail_exit verify SMOKE_RENAME_FILE_FAIL old_or_new_path_wrong
stat "${NEW}" >"${ARTIFACT_DIR}/renamed-stat.txt" 2>&1 || true
r4_log RENAME "old=${OLD}" "new=${NEW}"
RESULT=PASS
printf 'SMOKE_RENAME_FILE_PASS old="%s" new="%s"\n' "${OLD}" "${NEW}"
