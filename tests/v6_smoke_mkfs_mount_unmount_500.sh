#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_mkfs_mount_unmount_500 V6_MKFS_MOUNT_UNMOUNT_500_BEGIN
trap r4_v6_finish EXIT
CYCLES=${V6_CYCLES:-500}; SIZE=${V6_IMAGE_SIZE:-128M}; MNT=/tmp/reiser4-v6-mkfs-mnt
r4_v6_require_root_and_tools V6_MKFS_MOUNT_UNMOUNT_CYCLE_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_MKFS_MOUNT_UNMOUNT_CYCLE_FAIL preexisting_dirty_state=1
for cycle in $(seq 1 "${CYCLES}"); do
  IMAGE="${ARTIFACT_DIR}/cycle-${cycle}.img"
  if ! r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}"; then printf 'V6_MKFS_MOUNT_UNMOUNT_CYCLE_FAIL cycle=%s stage=mkfs_mount\n' "$cycle"; FAILED_STAGE="mkfs_mount_${cycle}"; exit 1; fi
  findmnt "${MNT}" >"${ARTIFACT_DIR}/findmnt-cycle-${cycle}.txt" 2>&1 || true
  stat "${MNT}" >"${ARTIFACT_DIR}/root-stat-cycle-${cycle}.txt" 2>&1 || { printf 'V6_MKFS_MOUNT_UNMOUNT_CYCLE_FAIL cycle=%s stage=root_stat\n' "$cycle"; FAILED_STAGE="root_stat_${cycle}"; exit 1; }
  loopdev=$(findmnt -rn -o SOURCE "${MNT}" 2>/dev/null || true); r4_log CYCLE "cycle=${cycle}" "mount_options=loop" "loop_device=${loopdev}" "module_refcount=$(r4_module_refcount)"
  if ! r4_v6_unmount_image "${IMAGE}" "${MNT}"; then printf 'V6_MKFS_MOUNT_UNMOUNT_CYCLE_FAIL cycle=%s stage=unmount_detach\n' "$cycle"; FAILED_STAGE="unmount_${cycle}"; exit 1; fi
  if r4_module_loaded && ! rmmod reiser4; then printf 'V6_MKFS_MOUNT_UNMOUNT_CYCLE_FAIL cycle=%s stage=rmmod\n' "$cycle"; printf 'V6_RMMOD_FAIL module_ref_stuck=%s\n' "$(r4_module_refcount)"; FAILED_STAGE="rmmod_${cycle}"; exit 1; fi
  printf 'V6_MKFS_MOUNT_UNMOUNT_CYCLE_PASS cycle=%s\n' "$cycle"
done
RESULT=PASS
printf 'V6_MKFS_MOUNT_UNMOUNT_500_PASS cycles=%s\n' "${CYCLES}"
