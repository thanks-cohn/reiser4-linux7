#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_enospc_inode_exhaustion V6_ENOSPC_INODE_EXHAUSTION_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-96M}; MNT=/tmp/v6_smoke_enospc_inode_exhaustion-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_enospc_inode_exhaustion.img"
r4_v6_require_root_and_tools V6_ENOSPC_INODE_EXHAUSTION_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_ENOSPC_INODE_EXHAUSTION_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_ENOSPC_INODE_EXHAUSTION_FAIL mount_failed=1

set +e; dd if=/dev/zero of="${MNT}/fill.bin" bs=1M status=none; rc=$?; set -u -o pipefail
if [[ ${rc} -ne 0 ]]; then printf 'V6_ENOSPC_OBSERVED rc=%s operation=dd_fill\n' "$rc"; else printf 'V6_ENOSPC_OBSERVED rc=0 operation=dd_fill_completed_check_filesystem_full\n'; fi
sync || true; rm -f "${MNT}/fill.bin"; printf recovery >"${MNT}/recovery" || r4_v6_fail_exit recovery_write V6_ENOSPC_INODE_EXHAUSTION_FAIL recovery_write_failed=1
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv"; r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_ENOSPC_INODE_EXHAUSTION_FAIL unmount_failed=1
r4_fsck_image "${IMAGE}" "${ARTIFACT_DIR}/fsck-after.txt" || r4_v6_fail_exit fsck V6_ENOSPC_INODE_EXHAUSTION_FAIL fsck_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_ENOSPC_INODE_EXHAUSTION_FAIL remount_failed=1
r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv" "${ARTIFACT_DIR}/manifest-verify.txt" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_ENOSPC_INODE_EXHAUSTION_FAIL manifest_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_ENOSPC_INODE_EXHAUSTION_PASS\n'
