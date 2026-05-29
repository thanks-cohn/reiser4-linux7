#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_mkdir_basic SMOKE_MKDIR_BASIC
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_MKDIR_BASIC_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

DIR=${MNT}/basic-dir
if ! out=$(mkdir "${DIR}" 2>&1); then
	FAILED_STAGE=mkdir
	printf 'SMOKE_MKDIR_BASIC_FAIL error="%s"\n' "$(r4_quote_msg "${out}")"
	exit 1
fi
stat "${DIR}" >"${ARTIFACT_DIR}/dir-stat.txt" 2>&1 || true
grep -i 'BUMRUSH26_MKDIR' "${ARTIFACT_DIR}/dmesg-after.txt" >"${ARTIFACT_DIR}/bumrush26-mkdir.txt" 2>/dev/null || true
RESULT=PASS
printf 'SMOKE_MKDIR_BASIC_PASS path="%s"\n' "${DIR}"
