#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); cd "${ROOT_DIR}"; source tests/lib/reiser4_test_lib.sh
if [[ ${EUID} -ne 0 ]]; then if command -v sudo >/dev/null 2>&1; then exec sudo -E bash "$0" "$@"; fi; echo 'SMOKE_PREFLIGHT_FAIL root_or_sudo_required=1'; exit 1; fi
TEST_NAME=smoke_mkfs_mount_unmount; ARTIFACT_DIR=$(r4_make_artifact_dir "${TEST_NAME}")
IMAGE=${REISER4_MKFS_MOUNT_IMAGE:-/tmp/reiser4-mkfs-mount.img}; MNT=${REISER4_MKFS_MOUNT_MNT:-/tmp/reiser4-mkfs-mount-mnt}; SIZE=${REISER4_SMOKE_SIZE:-128M}
RESULT=FAIL; FAILED_STAGE=none; MODULE_LOADED_BEFORE=0; MODULE_UNLOADED_AFTER=0; KTXNMGRD_ALIVE_AFTER=0; LOOP_STUCK_AFTER=0; DMESG_DANGER=0
finish(){ local rc=$?; r4_save_dmesg "${ARTIFACT_DIR}" before-cleanup; r4_try_cleanup "${ARTIFACT_DIR}"; r4_module_loaded || MODULE_UNLOADED_AFTER=1; r4_ktxnmgrd_alive && KTXNMGRD_ALIVE_AFTER=1 || true; r4_any_reiser4_loop_exists && LOOP_STUCK_AFTER=1 || true; if r4_dmesg_scan final >"${ARTIFACT_DIR}/dmesg-final-scan.txt" 2>&1; then DMESG_DANGER=0; else DMESG_DANGER=1; fi; cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
TEST=${TEST_NAME}
RESULT=${RESULT}
FAILED_STAGE=${FAILED_STAGE}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
IMAGE=${IMAGE}
MOUNTPOINT=${MNT}
MODULE_LOADED_BEFORE=${MODULE_LOADED_BEFORE}
MODULE_UNLOADED_AFTER=${MODULE_UNLOADED_AFTER}
KTXNMGRD_ALIVE_AFTER=${KTXNMGRD_ALIVE_AFTER}
LOOP_STUCK_AFTER=${LOOP_STUCK_AFTER}
DMESG_DANGER=${DMESG_DANGER}
SUMMARY
printf 'SMOKE_ARTIFACTS_AT %s\n' "${ARTIFACT_DIR}"; printf 'REISER4_SMOKE_END test=%s result=%s failed_stage=%s\n' "${TEST_NAME}" "${RESULT}" "${FAILED_STAGE}"; exit ${rc}; }
trap finish EXIT
fail_stage(){ FAILED_STAGE=$1; shift; printf '%s\n' "$*"; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; }
printf 'REISER4_SMOKE_BEGIN test=%s artifact_dir=%s\n' "${TEST_NAME}" "${ARTIFACT_DIR}"; r4_save_state "${ARTIFACT_DIR}" before-test; r4_save_dmesg "${ARTIFACT_DIR}" before-test
r4_module_loaded && MODULE_LOADED_BEFORE=1
[[ ${MODULE_LOADED_BEFORE} -eq 0 ]] || { R4_SKIP_RMMOD=1; fail_stage preflight 'SMOKE_PREFLIGHT_FAIL module_preloaded=1'; }
[[ -e reiser4.ko ]] || fail_stage preflight 'SMOKE_PREFLIGHT_FAIL missing_module=1 path="reiser4.ko"'
command -v mkfs.reiser4 >/dev/null 2>&1 || fail_stage preflight 'SMOKE_PREFLIGHT_FAIL missing_mkfs_reiser4=1'
mkdir -p "${MNT}" || fail_stage preflight "SMOKE_PREFLIGHT_FAIL mkdir_mountpoint=1 path=\"${MNT}\""
echo 'SMOKE_PREFLIGHT_PASS'
rm -f "${IMAGE}"; truncate -s "${SIZE}" "${IMAGE}" || fail_stage mkfs "SMOKE_MKFS_FAIL stage=truncate image=\"${IMAGE}\""
if ! out=$(mkfs.reiser4 -f "${IMAGE}" 2>&1); then printf '%s\n' "${out}" >"${ARTIFACT_DIR}/mkfs.log"; fail_stage mkfs "SMOKE_MKFS_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; printf '%s\n' "${out}" >"${ARTIFACT_DIR}/mkfs.log"; echo 'SMOKE_MKFS_PASS'
if ! out=$(insmod ./reiser4.ko 2>&1); then fail_stage insmod "SMOKE_INSMOD_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; echo 'SMOKE_INSMOD_PASS'
if ! out=$(mount -t reiser4 -o loop "${IMAGE}" "${MNT}" 2>&1); then fail_stage mount "SMOKE_MOUNT_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; echo 'SMOKE_MOUNT_PASS'
stat "${MNT}" >"${ARTIFACT_DIR}/root-stat.txt" 2>&1 || fail_stage root_stat 'SMOKE_ROOT_STAT_FAIL'; echo 'SMOKE_ROOT_STAT_PASS'
sync || fail_stage sync 'SMOKE_SYNC_FAIL'; echo 'SMOKE_SYNC_PASS'
if ! out=$(umount "${MNT}" 2>&1); then fail_stage unmount "SMOKE_UNMOUNT_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; echo 'SMOKE_UNMOUNT_PASS'
if ! out=$(rmmod reiser4 2>&1); then fail_stage rmmod "SMOKE_RMMOD_FAIL module_ref_stuck=1 error=\"$(r4_quote_msg "${out}")\""; fi; echo 'SMOKE_RMMOD_PASS'
RESULT=PASS; exit 0
