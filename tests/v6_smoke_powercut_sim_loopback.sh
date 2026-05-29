#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_powercut_sim_loopback V6_POWERCUT_SIM_LOOPBACK_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-512M}; MNT=/tmp/v6_smoke_powercut_sim_loopback-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_powercut_sim_loopback.img"
r4_v6_require_root_and_tools V6_POWERCUT_SIM_LOOPBACK_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_POWERCUT_SIM_LOOPBACK_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_POWERCUT_SIM_LOOPBACK_FAIL mount_failed=1

mkdir -p "${MNT}/powercut"; for i in $(seq 1 100); do printf 'stable=%s\n' "$i" >"${MNT}/powercut/stable-$i"; done; sync; r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-pre-crash.tsv"
for i in $(seq 1 20); do printf 'dirty=%s\n' "$i" >"${MNT}/powercut/dirty-$i"; done
umount -l "${MNT}" >/dev/null 2>&1 || true; while IFS= read -r dev; do [[ -n ${dev} ]] && losetup -d "${dev}" >/dev/null 2>&1 || true; done < <(losetup -j "${IMAGE}" 2>/dev/null | cut -d: -f1 || true)
r4_fsck_image "${IMAGE}" "${ARTIFACT_DIR}/fsck-after-powercut-sim.txt" || r4_v6_fail_exit fsck V6_POWERCUT_SIM_LOOPBACK_FAIL fsck_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_POWERCUT_SIM_LOOPBACK_FAIL remount_failed=1
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-post-recovery.tsv"; r4_verify_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest-pre-crash.tsv" "${ARTIFACT_DIR}/manifest-verify-stable.txt" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_POWERCUT_SIM_LOOPBACK_FAIL stable_manifest_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_POWERCUT_SIM_LOOPBACK_PASS\n'
