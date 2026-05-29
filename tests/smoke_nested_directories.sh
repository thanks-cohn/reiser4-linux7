#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_nested_directories SMOKE_NESTED_DIRECTORIES
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_NESTED_DIRECTORIES_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

DIR=${MNT}/a/b/c/d/e; FILE=${DIR}/nested.txt
mkdir -p "${DIR}" >"${ARTIFACT_DIR}/mkdir.log" 2>&1 || r4_fail_exit mkdir SMOKE_NESTED_DIRECTORIES_FAIL "$(cat "${ARTIFACT_DIR}/mkdir.log")"
printf 'nested payload\n' >"${FILE}" || r4_fail_exit write SMOKE_NESTED_DIRECTORIES_FAIL write_failed
find "${MNT}" -maxdepth 8 -print | sort >"${ARTIFACT_DIR}/tree-before-remount.txt" 2>&1 || true
sync; umount "${MNT}" || r4_fail_exit unmount SMOKE_NESTED_DIRECTORIES_FAIL unmount_failed
mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_fail_exit remount SMOKE_NESTED_DIRECTORIES_FAIL remount_failed
find "${MNT}" -maxdepth 8 -print | sort >"${ARTIFACT_DIR}/tree-after-remount.txt" 2>&1 || true
[[ -f ${FILE} ]] || r4_fail_exit verify SMOKE_NESTED_DIRECTORIES_FAIL missing_nested_file
r4_log NESTED "full_path=${FILE}" "depth=5"
RESULT=PASS
printf 'SMOKE_NESTED_DIRECTORIES_PASS path="%s" depth=5\n' "${FILE}"
