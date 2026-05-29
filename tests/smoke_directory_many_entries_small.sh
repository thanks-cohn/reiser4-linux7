#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_directory_many_entries_small SMOKE_DIRECTORY_MANY_ENTRIES_SMALL
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

DIR=${MNT}/many; mkdir "${DIR}" || r4_fail_exit mkdir SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL mkdir_failed
for i in $(seq -w 1 100); do printf 'file %s\n' "$i" >"${DIR}/file-${i}.txt" || r4_fail_exit write SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL "write ${i} failed"; done
actual=$(find "${DIR}" -maxdepth 1 -type f | wc -l)
find "${DIR}" -maxdepth 1 -type f -print | sort >"${ARTIFACT_DIR}/listing-before.txt"
sha256sum "${DIR}/file-001.txt" "${DIR}/file-050.txt" "${DIR}/file-100.txt" >"${ARTIFACT_DIR}/sample-hashes-before.txt" 2>&1 || true
[[ ${actual} -eq 100 ]] || r4_fail_exit count SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL "expected 100 actual ${actual}"
sync; umount "${MNT}" || r4_fail_exit unmount SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL unmount_failed
mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_fail_exit remount SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL remount_failed
actual2=$(find "${DIR}" -maxdepth 1 -type f | wc -l)
sha256sum "${DIR}/file-001.txt" "${DIR}/file-050.txt" "${DIR}/file-100.txt" >"${ARTIFACT_DIR}/sample-hashes-after.txt" 2>&1 || true
[[ ${actual2} -eq 100 ]] || r4_fail_exit remount_count SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_FAIL "expected 100 actual ${actual2}"
r4_log MANY_ENTRIES "expected=100" "actual=${actual2}"
RESULT=PASS
printf 'SMOKE_DIRECTORY_MANY_ENTRIES_SMALL_PASS expected=100 actual=%s\n' "${actual2}"
