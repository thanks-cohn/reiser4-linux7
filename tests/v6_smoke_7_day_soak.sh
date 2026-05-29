#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_7_day_soak V6_7_DAY_SOAK_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-2G}; MNT=/tmp/v6_smoke_7_day_soak-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_7_day_soak.img"
r4_v6_require_root_and_tools V6_7_DAY_SOAK_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_7_DAY_SOAK_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_7_DAY_SOAK_FAIL mount_failed=1

HOURS=${V6_SOAK_HOURS:-168}; mkdir -p "${MNT}/soak"; ops=0
for hour in $(seq 1 "${HOURS}"); do
  for i in $(seq 1 100); do printf 'hour=%s op=%s\n' "$hour" "$i" >"${MNT}/soak/h${hour}-f${i}"; mv "${MNT}/soak/h${hour}-f${i}" "${MNT}/soak/h${hour}-f${i}.renamed"; cat "${MNT}/soak/h${hour}-f${i}.renamed" >/dev/null || r4_v6_fail_exit workload V6_7_DAY_SOAK_FAIL "hour=${hour} op=${i}"; ops=$((ops+1)); done
  sync; r4_save_dmesg "${ARTIFACT_DIR}/dmesg-hour-${hour}.txt"; r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-hour-${hour}.txt" "${ARTIFACT_DIR}/dmesg-hour-${hour}-filtered.txt"; r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-hour-${hour}.txt" || r4_v6_fail_exit dmesg V6_7_DAY_SOAK_FAIL "hour=${hour}"
  printf 'hour=%s ops_total=%s\n' "$hour" "$ops" >"${ARTIFACT_DIR}/hour-${hour}-summary.txt"; printf 'V6_SOAK_HOUR_PASS hour=%s\n' "$hour"
done
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-final.tsv"; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_7_DAY_SOAK_FAIL unmount_failed=1
r4_fsck_image "${IMAGE}" "${ARTIFACT_DIR}/fsck-final.txt" || r4_v6_fail_exit fsck V6_7_DAY_SOAK_FAIL fsck_failed=1

RESULT=PASS
printf 'V6_7_DAY_SOAK_PASS\n'
