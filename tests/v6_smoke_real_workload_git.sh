#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_real_workload_git V6_REAL_WORKLOAD_GIT_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-2G}; MNT=/tmp/v6_smoke_real_workload_git-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_real_workload_git.img"
r4_v6_require_root_and_tools V6_REAL_WORKLOAD_GIT_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_REAL_WORKLOAD_GIT_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_REAL_WORKLOAD_GIT_FAIL mount_failed=1

git clone --no-hardlinks . "${MNT}/repo" >"${ARTIFACT_DIR}/git-clone.log" 2>&1 || r4_v6_fail_exit clone V6_REAL_WORKLOAD_GIT_FAIL clone_failed=1
(cd "${MNT}/repo" && git fsck >"${ARTIFACT_DIR}/git-fsck-before.txt" 2>&1 && git status --short >"${ARTIFACT_DIR}/git-status-before.txt" && printf v6 >v6-git-smoke-file && git add v6-git-smoke-file && git -c user.email=v6@example.invalid -c user.name='V6 Smoke' commit -m 'v6 smoke local commit' >"${ARTIFACT_DIR}/git-commit.txt" 2>&1 && git mv v6-git-smoke-file v6-git-smoke-file.renamed && git status --short >"${ARTIFACT_DIR}/git-status-after.txt") || r4_v6_fail_exit git_ops V6_REAL_WORKLOAD_GIT_FAIL git_ops_failed=1
(cd "${MNT}/repo" && git count-objects -v >"${ARTIFACT_DIR}/git-count-objects.txt" && git fsck >"${ARTIFACT_DIR}/git-fsck-after.txt" 2>&1) || r4_v6_fail_exit git_fsck V6_REAL_WORKLOAD_GIT_FAIL git_fsck_failed=1
r4_hash_manifest "${MNT}/repo/.git" "${ARTIFACT_DIR}/git-manifest.tsv"; sync
r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_REAL_WORKLOAD_GIT_FAIL unmount_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_REAL_WORKLOAD_GIT_FAIL remount_failed=1
(cd "${MNT}/repo" && git fsck >"${ARTIFACT_DIR}/git-fsck-remount.txt" 2>&1) || r4_v6_fail_exit verify V6_REAL_WORKLOAD_GIT_FAIL git_fsck_remount_failed=1
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_REAL_WORKLOAD_GIT_PASS\n'
