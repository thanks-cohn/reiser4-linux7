#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
source tests/lib/reiser4_test_lib.sh
if [[ ${EUID} -ne 0 ]]; then
	if command -v sudo >/dev/null 2>&1; then exec sudo -E bash "$0" "$@"; fi
	echo 'SMOKE_PREFLIGHT_FAIL root_or_sudo_required=1'; exit 1
fi
TEST_NAME=smoke_module_lifecycle
ARTIFACT_DIR=$(r4_make_artifact_dir "${TEST_NAME}")
RESULT=FAIL; FAILED_STAGE=none; DMESG_DANGER=0; MODULE_LOADED_BEFORE=0; MODULE_UNLOADED_AFTER=0; KTXNMGRD_ALIVE_AFTER=0; LOOP_STUCK_AFTER=0
finish(){ local rc=$?; r4_save_dmesg "${ARTIFACT_DIR}" before-cleanup; r4_try_cleanup "${ARTIFACT_DIR}"; r4_module_loaded || MODULE_UNLOADED_AFTER=1; r4_ktxnmgrd_alive && KTXNMGRD_ALIVE_AFTER=1 || true; r4_any_reiser4_loop_exists && LOOP_STUCK_AFTER=1 || true; if r4_dmesg_scan final >"${ARTIFACT_DIR}/dmesg-final-scan.txt" 2>&1; then DMESG_DANGER=0; else DMESG_DANGER=1; fi; cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
TEST=${TEST_NAME}
RESULT=${RESULT}
FAILED_STAGE=${FAILED_STAGE}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
MODULE_LOADED_BEFORE=${MODULE_LOADED_BEFORE}
MODULE_UNLOADED_AFTER=${MODULE_UNLOADED_AFTER}
KTXNMGRD_ALIVE_AFTER=${KTXNMGRD_ALIVE_AFTER}
LOOP_STUCK_AFTER=${LOOP_STUCK_AFTER}
DMESG_DANGER=${DMESG_DANGER}
SUMMARY
printf 'SMOKE_ARTIFACTS_AT %s\n' "${ARTIFACT_DIR}"; printf 'REISER4_SMOKE_END test=%s result=%s failed_stage=%s\n' "${TEST_NAME}" "${RESULT}" "${FAILED_STAGE}"; exit ${rc}; }
trap finish EXIT
printf 'REISER4_SMOKE_BEGIN test=%s artifact_dir=%s\n' "${TEST_NAME}" "${ARTIFACT_DIR}"
r4_save_state "${ARTIFACT_DIR}" before-test; r4_save_dmesg "${ARTIFACT_DIR}" before-test
if r4_module_loaded; then MODULE_LOADED_BEFORE=1; FAILED_STAGE=preflight; R4_SKIP_RMMOD=1; echo 'SMOKE_PREFLIGHT_FAIL module_preloaded=1'; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; fi
[[ -e reiser4.ko ]] || { FAILED_STAGE=preflight; echo 'SMOKE_PREFLIGHT_FAIL missing_module=1 path="reiser4.ko"'; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; }
echo 'SMOKE_PREFLIGHT_PASS'
if ! out=$(insmod ./reiser4.ko 2>&1); then FAILED_STAGE=insmod; printf 'SMOKE_INSMOD_FAIL error="%s"\n' "$(r4_quote_msg "${out}")"; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; fi
echo 'SMOKE_MODULE_INSMOD_PASS'; echo 'SMOKE_INSMOD_PASS'
if ! lsmod | awk '{print $1}' | grep -qx reiser4; then FAILED_STAGE=lsmod; echo 'SMOKE_INSMOD_FAIL lsmod_missing=1'; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; fi
if ! grep -q reiser4 /proc/filesystems; then FAILED_STAGE=proc_filesystems; echo 'SMOKE_MODULE_PROCFS_FAIL reiser4_missing=1'; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; fi
echo 'SMOKE_MODULE_PROCFS_PASS'
if ! out=$(rmmod reiser4 2>&1); then FAILED_STAGE=rmmod; printf 'SMOKE_RMMOD_FAIL lifecycle_problem=1 error="%s"\n' "$(r4_quote_msg "${out}")"; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; fi
if r4_module_loaded; then FAILED_STAGE=rmmod; echo 'SMOKE_RMMOD_FAIL module_still_loaded=1'; r4_save_state "${ARTIFACT_DIR}" after-failure; exit 1; fi
echo 'SMOKE_MODULE_RMMOD_PASS'; echo 'SMOKE_RMMOD_PASS'; RESULT=PASS; exit 0
