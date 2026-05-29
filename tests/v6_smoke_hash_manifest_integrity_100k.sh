#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_hash_manifest_integrity_100k V6_HASH_MANIFEST_INTEGRITY_100K_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-1G}; MNT=/tmp/v6_smoke_hash_manifest_integrity_100k-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_hash_manifest_integrity_100k.img"
r4_v6_require_root_and_tools V6_HASH_MANIFEST_INTEGRITY_100K_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_HASH_MANIFEST_INTEGRITY_100K_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_HASH_MANIFEST_INTEGRITY_100K_FAIL mount_failed=1

COUNT=${V6_FILE_COUNT:-100000}; mkdir -p "${MNT}/files"
for i in $(seq 1 "${COUNT}"); do printf 'file=%06d\n' "$i" >"${MNT}/files/file-$(printf '%06d' "$i")" || r4_v6_fail_exit create V6_HASH_MANIFEST_INTEGRITY_100K_FAIL "create failed at ${i}"; done
actual=$(find "${MNT}/files" -type f | wc -l | tr -d ' '); [[ ${actual} -eq ${COUNT} ]] || r4_v6_fail_exit count V6_HASH_MANIFEST_INTEGRITY_100K_FAIL "actual=${actual} expected=${COUNT}"
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-before.tsv"; printf 'V6_HASH_MANIFEST_CREATE_PASS expected=%s actual=%s\n' "${COUNT}" "${actual}"
sync; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_HASH_MANIFEST_INTEGRITY_100K_FAIL unmount_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_HASH_MANIFEST_INTEGRITY_100K_FAIL remount_failed=1
if ! r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-before.tsv" "${ARTIFACT_DIR}/manifest-verify.txt"; then SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_HASH_MANIFEST_INTEGRITY_100K_FAIL manifest_mismatch=1; fi
printf 'V6_HASH_MANIFEST_VERIFY_PASS\n'
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_HASH_MANIFEST_INTEGRITY_100K_PASS
'
