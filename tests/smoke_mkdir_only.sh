#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd); cd "${ROOT_DIR}"; source tests/lib/reiser4_test_lib.sh
if [[ ${EUID} -ne 0 ]]; then if command -v sudo >/dev/null 2>&1; then exec sudo -E bash "$0" "$@"; fi; echo 'SMOKE_PREFLIGHT_FAIL root_or_sudo_required=1'; exit 1; fi
TEST_NAME=smoke_mkdir_only; ARTIFACT_DIR=$(r4_make_artifact_dir "${TEST_NAME}")
IMAGE=${REISER4_MKDIR_IMAGE:-/tmp/reiser4-mkdir.img}; MNT=${REISER4_MKDIR_MNT:-/tmp/reiser4-mkdir-mnt}; SIZE=${REISER4_SMOKE_SIZE:-128M}; DIRPATH=${MNT}/dir
RESULT=FAIL; FAILED_STAGE=none; MKDIR_RESULT=SKIP; MKDIR_ERROR=; MODULE_LOADED_BEFORE=0; MODULE_UNLOADED_AFTER=0; KTXNMGRD_ALIVE_AFTER=0; LOOP_STUCK_AFTER=0; DMESG_DANGER=0; CLEANUP_OK=0
finish(){ local rc=$?; r4_save_dmesg "${ARTIFACT_DIR}" before-cleanup; r4_try_cleanup "${ARTIFACT_DIR}"; r4_module_loaded || MODULE_UNLOADED_AFTER=1; r4_ktxnmgrd_alive && KTXNMGRD_ALIVE_AFTER=1 || true; r4_any_reiser4_loop_exists && LOOP_STUCK_AFTER=1 || true; [[ ${MODULE_UNLOADED_AFTER} -eq 1 && ${KTXNMGRD_ALIVE_AFTER} -eq 0 && ${LOOP_STUCK_AFTER} -eq 0 ]] && CLEANUP_OK=1 || true; if r4_dmesg_scan final >"${ARTIFACT_DIR}/dmesg-final-scan.txt" 2>&1; then DMESG_DANGER=0; else DMESG_DANGER=1; fi; cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
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
MKDIR_RESULT=${MKDIR_RESULT}
MKDIR_ERROR=${MKDIR_ERROR}
CLEANUP_OK=${CLEANUP_OK}
SUMMARY
printf 'SMOKE_CLEANUP_%s\n' "$([[ ${CLEANUP_OK} -eq 1 ]] && echo PASS || echo FAIL)"; printf 'SMOKE_ARTIFACTS_AT %s\n' "${ARTIFACT_DIR}"; printf 'REISER4_SMOKE_END test=%s result=%s failed_stage=%s\n' "${TEST_NAME}" "${RESULT}" "${FAILED_STAGE}"; exit ${rc}; }
trap finish EXIT
fail_stage(){ FAILED_STAGE=$1; shift; printf '%s\n' "$*"; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; }
printf 'REISER4_SMOKE_BEGIN test=%s artifact_dir=%s\n' "${TEST_NAME}" "${ARTIFACT_DIR}"; r4_save_state "${ARTIFACT_DIR}" before-test; r4_save_dmesg "${ARTIFACT_DIR}" before-test
r4_module_loaded && MODULE_LOADED_BEFORE=1; [[ ${MODULE_LOADED_BEFORE} -eq 0 ]] || { R4_SKIP_RMMOD=1; fail_stage preflight 'SMOKE_PREFLIGHT_FAIL module_preloaded=1'; }
[[ -e reiser4.ko ]] || fail_stage preflight 'SMOKE_PREFLIGHT_FAIL missing_module=1 path="reiser4.ko"'; command -v mkfs.reiser4 >/dev/null 2>&1 || fail_stage preflight 'SMOKE_PREFLIGHT_FAIL missing_mkfs_reiser4=1'; mkdir -p "${MNT}" || fail_stage preflight "SMOKE_PREFLIGHT_FAIL mkdir_mountpoint=1 path=\"${MNT}\""; echo 'SMOKE_PREFLIGHT_PASS'
rm -f "${IMAGE}"; truncate -s "${SIZE}" "${IMAGE}" || fail_stage mkfs "SMOKE_MKFS_FAIL stage=truncate image=\"${IMAGE}\""; if ! out=$(mkfs.reiser4 -f "${IMAGE}" 2>&1); then printf '%s\n' "${out}" >"${ARTIFACT_DIR}/mkfs.log"; fail_stage mkfs "SMOKE_MKFS_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; printf '%s\n' "${out}" >"${ARTIFACT_DIR}/mkfs.log"; echo 'SMOKE_MKFS_PASS'
if ! out=$(insmod ./reiser4.ko 2>&1); then fail_stage insmod "SMOKE_INSMOD_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; echo 'SMOKE_INSMOD_PASS'
if ! out=$(mount -t reiser4 -o loop "${IMAGE}" "${MNT}" 2>&1); then fail_stage mount "SMOKE_MOUNT_FAIL error=\"$(r4_quote_msg "${out}")\""; fi; echo 'SMOKE_MOUNT_PASS'
if out=$(mkdir "${DIRPATH}" 2>&1); then MKDIR_RESULT=PASS; echo "SMOKE_MKDIR_PASS path=${DIRPATH}"; RESULT=PASS; exit 0; else MKDIR_RESULT=FAIL; MKDIR_ERROR=${out}; FAILED_STAGE=mkdir; printf 'SMOKE_MKDIR_FAIL error="%s"\n' "$(r4_quote_msg "${out}")"; r4_save_state "${ARTIFACT_DIR}" after-failure; r4_save_dmesg "${ARTIFACT_DIR}" after-mkdir-failure; grep -E 'BUMRUSH26_MKDIR' "${ARTIFACT_DIR}/dmesg-after-mkdir-failure.txt" >"${ARTIFACT_DIR}/bumrush26-mkdir.txt" 2>/dev/null || true; exit 1; fi
