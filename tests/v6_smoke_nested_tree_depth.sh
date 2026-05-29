#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_nested_tree_depth V6_NESTED_TREE_DEPTH_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-512M}; MNT=/tmp/v6_smoke_nested_tree_depth-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_nested_tree_depth.img"
r4_v6_require_root_and_tools V6_NESTED_TREE_DEPTH_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_NESTED_TREE_DEPTH_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_NESTED_TREE_DEPTH_FAIL mount_failed=1

DEPTH=${V6_DEPTH:-128}; cur="${MNT}/tree"; mkdir -p "$cur"
for i in $(seq 1 "${DEPTH}"); do comp="d$(printf '%03d' "$i")"; cur="$cur/$comp"; mkdir "$cur" || r4_v6_fail_exit create V6_NESTED_TREE_DEPTH_FAIL "depth=${i}"; done
printf depth >"$cur/payload"; r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-before.tsv"; printf 'max_depth=%s path_length=%s component_length=4\n' "${DEPTH}" "${#cur}" >"${ARTIFACT_DIR}/depth-details.txt"
mv "$cur/payload" "$cur/payload.renamed"; rm -f "$cur/payload.renamed"; printf verify >"$cur/verify"; r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-after.tsv"
sync; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_NESTED_TREE_DEPTH_FAIL unmount_failed=1
r4_fsck_image "${IMAGE}" "${ARTIFACT_DIR}/fsck-after.txt" || r4_v6_fail_exit fsck V6_NESTED_TREE_DEPTH_FAIL fsck_failed=1

RESULT=PASS
printf 'V6_NESTED_TREE_DEPTH_PASS
'
