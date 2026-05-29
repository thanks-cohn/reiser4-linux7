#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_sync_pressure_small SMOKE_SYNC_PRESSURE_SMALL
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_SYNC_PRESSURE_SMALL_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

total=0
for i in $(seq -w 1 100); do data="sync pressure file ${i} $(date -u +%s%N)"; printf '%s\n' "${data}" >"${MNT}/sync-${i}.txt" || r4_fail_exit write SMOKE_SYNC_PRESSURE_SMALL_FAIL "write ${i} failed"; total=$((total + ${#data} + 1)); sync || r4_fail_exit sync SMOKE_SYNC_PRESSURE_SMALL_FAIL "sync ${i} failed"; done
r4_save_dmesg "${ARTIFACT_DIR}/dmesg-pressure.txt"; r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-pressure.txt" "${ARTIFACT_DIR}/dmesg-pressure-filtered.txt"
if ! r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-pressure.txt"; then r4_fail_exit dmesg SMOKE_SYNC_PRESSURE_SMALL_FAIL dmesg_danger; fi
r4_log SYNC_PRESSURE "count=100" "total_bytes=${total}"
RESULT=PASS
printf 'SMOKE_SYNC_PRESSURE_SMALL_PASS count=100 total_bytes=%s\n' "${total}"
