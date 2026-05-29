#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_full_v1_100 V6_FULL_V1_100_BEGIN
trap r4_v6_finish EXIT
CYCLES=${V6_CYCLES:-100}; SIZE=${V6_IMAGE_SIZE:-128M}; MNT=/tmp/reiser4-v6-v1-mnt
r4_v6_require_root_and_tools V6_FULL_V1_CYCLE_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_FULL_V1_CYCLE_FAIL preexisting_dirty_state=1
for cycle in $(seq 1 "${CYCLES}"); do
  IMAGE="${ARTIFACT_DIR}/v1-cycle-${cycle}.img"; stage=mount
  r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=mkdir; mkdir "${MNT}/dir" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=create; printf 'cycle=%s\n' "$cycle" >"${MNT}/dir/file" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=hash; sha256sum "${MNT}/dir/file" >"${ARTIFACT_DIR}/hash-cycle-${cycle}-before.txt" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=read; grep -q "cycle=${cycle}" "${MNT}/dir/file" || { SILENT_CORRUPTION=1; printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=rename; mv "${MNT}/dir/file" "${MNT}/dir/file.renamed" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=delete; rm -f "${MNT}/dir/file.renamed" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  printf 'verify-cycle=%s\n' "$cycle" >"${MNT}/verify"; r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-cycle-${cycle}.tsv"; sync
  stage=unmount; r4_v6_unmount_image "${IMAGE}" "${MNT}" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=remount; if ! r4_module_loaded; then insmod ./reiser4.ko || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }; fi; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=verify; r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-cycle-${cycle}.tsv" "${ARTIFACT_DIR}/verify-cycle-${cycle}.txt" || { SILENT_CORRUPTION=1; printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  stage=final_unmount; r4_v6_unmount_image "${IMAGE}" "${MNT}" || { printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=%s\n' "$cycle" "$stage"; FAILED_STAGE="${stage}_${cycle}"; exit 1; }
  if r4_module_loaded && ! rmmod reiser4; then printf 'V6_FULL_V1_CYCLE_FAIL cycle=%s stage=rmmod\n' "$cycle"; printf 'V6_RMMOD_FAIL module_ref_stuck=%s\n' "$(r4_module_refcount)"; FAILED_STAGE="rmmod_${cycle}"; exit 1; fi
  printf 'V6_FULL_V1_CYCLE_PASS cycle=%s\n' "$cycle"
done
RESULT=PASS
printf 'V6_FULL_V1_100_PASS cycles=%s\n' "${CYCLES}"
