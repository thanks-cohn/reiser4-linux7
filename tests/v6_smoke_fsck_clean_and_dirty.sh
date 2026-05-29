#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_fsck_clean_and_dirty V6_FSCK_CLEAN_AND_DIRTY_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-256M}; MNT=/tmp/reiser4-v6-fsck-mnt; CLEAN_IMAGE="${ARTIFACT_DIR}/clean.img"; DIRTY_IMAGE="${ARTIFACT_DIR}/dirty.img"
r4_v6_require_root_and_tools V6_FSCK_CLEAN_AND_DIRTY_FAIL
command -v fsck.reiser4 >/dev/null 2>&1 || r4_v6_fail_exit preflight V6_FSCK_CLEAN_AND_DIRTY_FAIL missing_fsck_reiser4=1
r4_log FSCK_VERSION "version=$(fsck.reiser4 -V 2>&1 | head -n 1 || echo unknown)"
r4_v6_mount_image "${CLEAN_IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit clean_mount V6_FSCK_CLEAN_AND_DIRTY_FAIL mount_failed=1
printf clean >"${MNT}/clean-file"; sync; r4_v6_unmount_image "${CLEAN_IMAGE}" "${MNT}" || r4_v6_fail_exit clean_unmount V6_FSCK_CLEAN_AND_DIRTY_FAIL unmount_failed=1
r4_fsck_image "${CLEAN_IMAGE}" "${ARTIFACT_DIR}/fsck-clean.txt"; clean_rc=$?; [[ ${clean_rc} -eq 0 ]] || r4_v6_fail_exit fsck_clean V6_FSCK_CLEAN_AND_DIRTY_FAIL "fsck clean rc=${clean_rc}"
printf 'V6_FSCK_CLEAN_PASS rc=%s\n' "${clean_rc}"
r4_v6_mount_image "${DIRTY_IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit dirty_mount V6_FSCK_CLEAN_AND_DIRTY_FAIL mount_failed=1
printf dirty >"${MNT}/dirty-file"; sync
umount -l "${MNT}" >/dev/null 2>&1 || true
while IFS= read -r dev; do [[ -n ${dev} ]] && losetup -d "${dev}" >/dev/null 2>&1 || true; done < <(losetup -j "${DIRTY_IMAGE}" 2>/dev/null | cut -d: -f1 || true)
r4_fsck_image "${DIRTY_IMAGE}" "${ARTIFACT_DIR}/fsck-dirty.txt"; dirty_rc=$?; [[ ${dirty_rc} -eq 0 ]] || r4_v6_fail_exit fsck_dirty V6_FSCK_CLEAN_AND_DIRTY_FAIL "fsck dirty rc=${dirty_rc}"
printf 'V6_FSCK_DIRTY_PASS rc=%s\n' "${dirty_rc}"
RESULT=PASS
printf 'V6_FSCK_CLEAN_AND_DIRTY_PASS\n'
