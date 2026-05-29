#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_small_file_pressure V6_SMALL_FILE_PRESSURE_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-2G}; MNT=/tmp/v6_smoke_small_file_pressure-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_small_file_pressure.img"
r4_v6_require_root_and_tools V6_SMALL_FILE_PRESSURE_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_SMALL_FILE_PRESSURE_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_SMALL_FILE_PRESSURE_FAIL mount_failed=1

COUNT=${V6_FILE_COUNT:-200000}; mkdir -p "${MNT}/tiny"; total=0
for i in $(seq 1 "${COUNT}"); do data="x$i"; total=$((total + ${#data})); printf '%s' "$data" >"${MNT}/tiny/f$(printf '%07d' "$i")" || r4_v6_fail_exit create V6_SMALL_FILE_PRESSURE_FAIL "file=${i}"; done
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv"; actual=$(find "${MNT}/tiny" -type f | wc -l | tr -d ' '); [[ ${actual} -eq ${COUNT} ]] || r4_v6_fail_exit count V6_SMALL_FILE_PRESSURE_FAIL "actual=${actual} expected=${COUNT}"
r4_log SMALL_FILE_PRESSURE "file_count=${COUNT}" "total_bytes=${total}" "metadata_behavior=sync_remount_fsck_verify"
sync; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_SMALL_FILE_PRESSURE_FAIL unmount_failed=1
r4_fsck_image "${IMAGE}" "${ARTIFACT_DIR}/fsck-after.txt" || r4_v6_fail_exit fsck V6_SMALL_FILE_PRESSURE_FAIL fsck_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_SMALL_FILE_PRESSURE_FAIL remount_failed=1
r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv" "${ARTIFACT_DIR}/manifest-verify.txt" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_SMALL_FILE_PRESSURE_FAIL manifest_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_SMALL_FILE_PRESSURE_PASS\n'
