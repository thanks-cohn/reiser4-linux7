#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_v3_short_stress SMOKE_V3_SHORT_STRESS
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_V3_SHORT_STRESS_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

BASE=${MNT}/stress/a/b/c; mkdir -p "${BASE}" || r4_fail_exit mkdir SMOKE_V3_SHORT_STRESS_FAIL mkdir_failed
for i in $(seq -w 1 500); do printf 'stress file %s\n' "$i" >"${BASE}/file-${i}.txt" || r4_fail_exit write SMOKE_V3_SHORT_STRESS_FAIL "write ${i} failed"; done
sha256sum "${BASE}"/file-*.txt | sort >"${ARTIFACT_DIR}/hashes-before.txt" 2>&1 || r4_fail_exit hash SMOKE_V3_SHORT_STRESS_FAIL hash_before_failed
for i in $(seq -w 1 100); do mv "${BASE}/file-${i}.txt" "${BASE}/renamed-${i}.txt" || r4_fail_exit rename SMOKE_V3_SHORT_STRESS_FAIL "rename ${i} failed"; done
for i in $(seq -w 101 200); do rm "${BASE}/file-${i}.txt" || r4_fail_exit delete SMOKE_V3_SHORT_STRESS_FAIL "delete ${i} failed"; done
sync || r4_fail_exit sync SMOKE_V3_SHORT_STRESS_FAIL sync_failed
find "${MNT}" -type f | sort >"${ARTIFACT_DIR}/files-before-remount.txt"
umount "${MNT}" || r4_fail_exit unmount SMOKE_V3_SHORT_STRESS_FAIL unmount_failed
mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_fail_exit remount SMOKE_V3_SHORT_STRESS_FAIL remount_failed
find "${MNT}" -type f | sort >"${ARTIFACT_DIR}/files-after-remount.txt"
count=$(find "${BASE}" -type f | wc -l)
[[ ${count} -eq 400 ]] || r4_fail_exit verify SMOKE_V3_SHORT_STRESS_FAIL "expected 400 files actual ${count}"
r4_log V3_STRESS "created=500" "renamed=100" "deleted=100" "remaining=${count}"
RESULT=PASS
printf 'SMOKE_V3_SHORT_STRESS_PASS created=500 renamed=100 deleted=100 remaining=%s\n' "${count}"
