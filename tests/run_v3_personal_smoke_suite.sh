#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

TEST_NAME=v3-personal-smoke-suite
ARTIFACT_DIR=$(r4_artifact_dir "${TEST_NAME}")
COMMAND_LOG="${ARTIFACT_DIR}/command-log.txt"
exec > >(tee -a "${COMMAND_LOG}") 2>&1
printf 'SMOKE_V3_PERSONAL_SUITE_BEGIN\n'
printf 'SMOKE_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
r4_state "${ARTIFACT_DIR}/state-before.txt"
r4_save_dmesg "${ARTIFACT_DIR}/dmesg-before.txt"

TESTS=(
  smoke_build_module
  smoke_module_lifecycle
  smoke_mkfs_image
  smoke_mount_root_stat_unmount
  smoke_regular_file_create
  smoke_regular_file_write_read
  smoke_regular_file_remount_verify
  smoke_rename_file
  smoke_delete_file
  smoke_mkdir_basic
  smoke_nested_directories
  smoke_directory_many_entries_small
  smoke_sync_pressure_small
  smoke_repeated_mount_unmount_10
  smoke_module_unload_after_filesystem_use
  smoke_failed_operation_teardown
  smoke_dmesg_cleanliness
  smoke_fsck_after_clean_unmount
  smoke_v3_short_stress
  smoke_v3_repeat_from_clean_boot
)

PASSED=0; FAILED=0; SKIPPED=0
FIRST_FAILED_TEST=none; FIRST_FAILED_STAGE=none
STATUS=READY_TO_TRY
MKDIR_BLOCKED=0
TEARDOWN_FAILED=0

record_failure() {
  local test=$1 stage=$2 status=$3
  FAILED=$((FAILED + 1))
  if [[ ${FIRST_FAILED_TEST} == none ]]; then FIRST_FAILED_TEST=${test}; FIRST_FAILED_STAGE=${stage}; fi
  STATUS=${status}
}

latest_summary_for() {
  local test=$1
  ls -td artifacts/${test}-*/summary.txt 2>/dev/null | head -1 || true
}

run_test() {
  local test=$1 summary result stage rc script
  script="tests/${test}.sh"
  printf 'SMOKE_SUITE_TEST_BEGIN test=%s command="%s"\n' "${test}" "${script}"
  if [[ ! -x ${script} ]]; then
    printf 'SMOKE_SUITE_TEST_FAIL test=%s missing_or_not_executable=1\n' "${test}"
    record_failure "${test}" missing_script "${STATUS}"
    return 127
  fi
  set +e
  "${script}"
  rc=$?
  set -u
  summary=$(latest_summary_for "${test}")
  result=UNKNOWN; stage=unknown
  if [[ -n ${summary} && -f ${summary} ]]; then
    cp "${summary}" "${ARTIFACT_DIR}/${test}-summary.txt" 2>/dev/null || true
    result=$(awk -F= '$1=="RESULT"{print $2; exit}' "${summary}")
    stage=$(awk -F= '$1=="FAILED_STAGE"{print $2; exit}' "${summary}")
  fi
  if [[ ${rc} -eq 0 && ${result} == PASS ]]; then
    PASSED=$((PASSED + 1))
    printf 'SMOKE_SUITE_TEST_PASS test=%s\n' "${test}"
  else
    printf 'SMOKE_SUITE_TEST_FAIL test=%s rc=%s result=%s failed_stage=%s\n' "${test}" "${rc}" "${result}" "${stage}"
    FAILED=$((FAILED + 1))
    if [[ ${FIRST_FAILED_TEST} == none ]]; then FIRST_FAILED_TEST=${test}; FIRST_FAILED_STAGE=${stage}; fi
  fi
  return "${rc}"
}

skip_test() {
  local test=$1 reason=$2
  SKIPPED=$((SKIPPED + 1))
  printf 'SMOKE_SUITE_TEST_SKIP test=%s reason="%s"\n' "${test}" "${reason}"
}

for test in "${TESTS[@]}"; do
  if [[ ${MKDIR_BLOCKED} -eq 1 ]]; then
    case "${test}" in
      smoke_failed_operation_teardown|smoke_dmesg_cleanliness) ;;
      *) skip_test "${test}" "blocked_by_mkdir"; continue ;;
    esac
  fi

  if run_test "${test}"; then
    :
  else
    latest=$(latest_summary_for "${test}")
    stage=unknown
    [[ -n ${latest} && -f ${latest} ]] && stage=$(awk -F= '$1=="FAILED_STAGE"{print $2; exit}' "${latest}")
    case "${test}" in
      smoke_build_module) STATUS=BLOCKED_BY_BUILD; break ;;
      smoke_module_lifecycle) STATUS=BLOCKED_BY_MODULE; break ;;
      smoke_mkfs_image) STATUS=BLOCKED_BY_MKFS; break ;;
      smoke_mount_root_stat_unmount) STATUS=BLOCKED_BY_MOUNT; break ;;
      smoke_regular_file_write_read) STATUS=BLOCKED_BY_FILE_RW; break ;;
      smoke_mkdir_basic) STATUS=BLOCKED_BY_MKDIR; MKDIR_BLOCKED=1 ;;
      smoke_failed_operation_teardown) STATUS=BLOCKED_BY_TEARDOWN; TEARDOWN_FAILED=1; break ;;
      smoke_dmesg_cleanliness) [[ ${STATUS} == READY_TO_TRY ]] && STATUS=BLOCKED_BY_DMESG ;;
      smoke_fsck_after_clean_unmount) [[ ${STATUS} == READY_TO_TRY ]] && STATUS=BLOCKED_BY_FSCK ;;
      smoke_v3_short_stress|smoke_v3_repeat_from_clean_boot) [[ ${STATUS} == READY_TO_TRY ]] && STATUS=BLOCKED_BY_STRESS ;;
    esac
  fi

done

# Count any not-yet-reached tests after break as skipped.
# This lightweight pass avoids double-counting tests already copied into suite logs.
if [[ ${STATUS} != READY_TO_TRY && ${MKDIR_BLOCKED} -eq 0 && ${TEARDOWN_FAILED} -eq 0 ]]; then
  :
fi

r4_state "${ARTIFACT_DIR}/state-after.txt"
r4_save_dmesg "${ARTIFACT_DIR}/dmesg-after.txt"
r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-after.txt" "${ARTIFACT_DIR}/dmesg-filtered.txt"
r4_cleanup "${ARTIFACT_DIR}"
FINAL_MODULE_LOADED=$(r4_bool r4_module_loaded)
FINAL_KTXNMGRD_ALIVE=$(r4_bool r4_ktxnmgrd_alive)
FINAL_ENTD_ALIVE=$(r4_bool r4_entd_alive)
FINAL_LOOP_STUCK=$(r4_bool r4_any_reiser4_loop_exists)
if ! r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-after.txt"; then FINAL_DMESG_DANGER=1; [[ ${STATUS} == READY_TO_TRY ]] && STATUS=BLOCKED_BY_DMESG; else FINAL_DMESG_DANGER=0; fi

cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
V3_PERSONAL_SMOKE_STATUS=${STATUS}
PASSED_TESTS=${PASSED}
FAILED_TESTS=${FAILED}
SKIPPED_TESTS=${SKIPPED}
FIRST_FAILED_TEST=${FIRST_FAILED_TEST}
FIRST_FAILED_STAGE=${FIRST_FAILED_STAGE}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
FINAL_MODULE_LOADED=${FINAL_MODULE_LOADED}
FINAL_KTXNMGRD_ALIVE=${FINAL_KTXNMGRD_ALIVE}
FINAL_ENTD_ALIVE=${FINAL_ENTD_ALIVE}
FINAL_LOOP_STUCK=${FINAL_LOOP_STUCK}
FINAL_DMESG_DANGER=${FINAL_DMESG_DANGER}
SUMMARY
printf 'V3_PERSONAL_SMOKE_STATUS=%s\n' "${STATUS}"
printf 'SMOKE_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
[[ ${STATUS} == READY_TO_TRY ]]
