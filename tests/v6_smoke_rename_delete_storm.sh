#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_rename_delete_storm V6_RENAME_DELETE_STORM_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-512M}; MNT=/tmp/v6_smoke_rename_delete_storm-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_rename_delete_storm.img"
r4_v6_require_root_and_tools V6_RENAME_DELETE_STORM_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_RENAME_DELETE_STORM_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_RENAME_DELETE_STORM_FAIL mount_failed=1

OPS=${V6_OPS:-10000}; mkdir -p "${MNT}/storm"
for i in $(seq 1 "${OPS}"); do f="${MNT}/storm/file-$i"; printf '%s' "$i" >"$f" || r4_v6_fail_exit create V6_RENAME_DELETE_STORM_FAIL "op=${i}"; mv "$f" "$f.renamed" || r4_v6_fail_exit rename V6_RENAME_DELETE_STORM_FAIL "op=${i}"; rm -f "$f.renamed" || r4_v6_fail_exit delete V6_RENAME_DELETE_STORM_FAIL "op=${i}"; done
printf final >"${MNT}/storm/final"; r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-final.tsv"; sync
r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_RENAME_DELETE_STORM_FAIL unmount_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_RENAME_DELETE_STORM_FAIL remount_failed=1
r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-final.tsv" "${ARTIFACT_DIR}/manifest-verify.txt" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_RENAME_DELETE_STORM_FAIL manifest_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_RENAME_DELETE_STORM_PASS
'
