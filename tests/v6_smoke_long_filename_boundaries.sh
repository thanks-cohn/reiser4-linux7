#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_long_filename_boundaries V6_LONG_FILENAME_BOUNDARIES_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-512M}; MNT=/tmp/v6_smoke_long_filename_boundaries-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_long_filename_boundaries.img"
r4_v6_require_root_and_tools V6_LONG_FILENAME_BOUNDARIES_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_LONG_FILENAME_BOUNDARIES_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_LONG_FILENAME_BOUNDARIES_FAIL mount_failed=1

lengths=(1 64 128 255 256 512 1024 2048 3976 4032 4096); max_ok=0; : >"${ARTIFACT_DIR}/long-name-results.tsv"
if [[ -x tests/large_filename_probe.sh ]]; then tests/large_filename_probe.sh >"${ARTIFACT_DIR}/large-filename-probe.log" 2>&1 || true; fi
for len in "${lengths[@]}"; do name=$(python3 -c "print('n' * ${len})"); if printf x >"${MNT}/${name}" 2>"${ARTIFACT_DIR}/long-name-${len}.err"; then max_ok=${len}; printf '%s\tPASS\t0\n' "$len" >>"${ARTIFACT_DIR}/long-name-results.tsv"; printf 'V6_LONG_FILENAME_BOUNDARY_SAFE_PASS length=%s\n' "$len"; else rc=$?; printf '%s\tFAIL\t%s\n' "$len" "$rc" >>"${ARTIFACT_DIR}/long-name-results.tsv"; printf 'V6_LONG_FILENAME_BOUNDARY_SAFE_FAIL length=%s errno=%s\n' "$len" "$rc"; fi; done
printf 'max_successful_length=%s\n' "$max_ok" >"${ARTIFACT_DIR}/long-name-summary.txt"
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv"; sync; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_LONG_FILENAME_BOUNDARIES_FAIL unmount_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_LONG_FILENAME_BOUNDARIES_FAIL remount_failed=1
r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv" "${ARTIFACT_DIR}/manifest-verify.txt" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_LONG_FILENAME_BOUNDARIES_FAIL manifest_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_LONG_FILENAME_BOUNDARIES_PASS\n'
