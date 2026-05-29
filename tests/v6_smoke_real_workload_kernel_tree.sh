#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_real_workload_kernel_tree V6_REAL_WORKLOAD_KERNEL_TREE_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-4G}; MNT=/tmp/v6_smoke_real_workload_kernel_tree-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_real_workload_kernel_tree.img"
r4_v6_require_root_and_tools V6_REAL_WORKLOAD_KERNEL_TREE_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_REAL_WORKLOAD_KERNEL_TREE_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_REAL_WORKLOAD_KERNEL_TREE_FAIL mount_failed=1

mkdir -p "${MNT}/workload"; fallback=1
if compgen -G "/usr/src/linux*.tar*" >/dev/null; then tarball=$(compgen -G "/usr/src/linux*.tar*" | head -1); tar -xf "$tarball" -C "${MNT}/workload" >"${ARTIFACT_DIR}/tar.log" 2>&1 || r4_v6_fail_exit unpack V6_REAL_WORKLOAD_KERNEL_TREE_FAIL tar_failed=1; fallback=0; else rsync -a --exclude artifacts --exclude .git . "${MNT}/workload/repo-copy" >"${ARTIFACT_DIR}/rsync.log" 2>&1 || cp -a . "${MNT}/workload/repo-copy"; fi
[[ ${fallback} -eq 1 ]] && printf 'V6_KERNEL_TREE_FALLBACK_REPO_WORKLOAD=1\n' | tee "${ARTIFACT_DIR}/fallback.txt"
find "${MNT}/workload" -type f | wc -l >"${ARTIFACT_DIR}/file-count.txt"; git status --short >"${ARTIFACT_DIR}/git-status-host.txt" 2>&1 || true
r4_hash_manifest "${MNT}/workload" "${ARTIFACT_DIR}/manifest.tsv"; mkdir -p "${MNT}/workload/build-like"; find "${MNT}/workload" -type f | head -100 | xargs -r -I{} cp {} "${MNT}/workload/build-like/" 2>/dev/null || true; rm -rf "${MNT}/workload/build-like"
sync; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_REAL_WORKLOAD_KERNEL_TREE_FAIL unmount_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_REAL_WORKLOAD_KERNEL_TREE_FAIL remount_failed=1
r4_verify_hash_manifest "${MNT}/workload" "${ARTIFACT_DIR}/manifest.tsv" "${ARTIFACT_DIR}/manifest-verify.txt" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_REAL_WORKLOAD_KERNEL_TREE_FAIL manifest_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_REAL_WORKLOAD_KERNEL_TREE_PASS\n'
