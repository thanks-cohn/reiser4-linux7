#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

ARTIFACT_DIR=$(r4_artifact_dir v6-smoke-suite)
COMMAND_LOG="${ARTIFACT_DIR}/command-log.txt"
exec > >(tee -a "${COMMAND_LOG}") 2>&1
printf 'V6_SMOKE_SUITE_BEGIN\n'
printf 'V6_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
r4_state "${ARTIFACT_DIR}/state-before.txt"
r4_save_dmesg "${ARTIFACT_DIR}/dmesg-before.txt"

names=(
 v6_smoke_clean_build_matrix
 v6_smoke_module_lifecycle_100
 v6_smoke_mkfs_mount_unmount_500
 v6_smoke_full_v1_100
 v6_smoke_v3_proof_30
 v6_smoke_teardown_after_failure_100
 v6_smoke_fsck_clean_and_dirty
 v6_smoke_hash_manifest_integrity_100k
 v6_smoke_directory_scale_1m
 v6_smoke_nested_tree_depth
 v6_smoke_rename_delete_storm
 v6_smoke_parallel_writers
 v6_smoke_large_file_streaming
 v6_smoke_small_file_pressure
 v6_smoke_real_workload_kernel_tree
 v6_smoke_real_workload_git
 v6_smoke_enospc_inode_exhaustion
 v6_smoke_long_filename_boundaries
 v6_smoke_powercut_sim_loopback
 v6_smoke_7_day_soak
)
statuses=(
 BLOCKED_BY_BUILD BLOCKED_BY_MODULE BLOCKED_BY_MKFS_MOUNT BLOCKED_BY_V1 BLOCKED_BY_V3
 BLOCKED_BY_TEARDOWN BLOCKED_BY_FSCK BLOCKED_BY_CORRUPTION BLOCKED_BY_SCALE BLOCKED_BY_SCALE
 BLOCKED_BY_CORRUPTION BLOCKED_BY_CORRUPTION BLOCKED_BY_CORRUPTION BLOCKED_BY_CORRUPTION
 BLOCKED_BY_REAL_WORKLOAD BLOCKED_BY_REAL_WORKLOAD BLOCKED_BY_ENOSPC BLOCKED_BY_LONG_NAMES
 BLOCKED_BY_CORRUPTION BLOCKED_BY_SOAK
)

passed=0; failed=0; skipped=0; first_failed=none; first_stage=none; suite_status=CANDIDATE
for idx in "${!names[@]}"; do
  name=${names[$idx]}; script="tests/${name}.sh"; log="${ARTIFACT_DIR}/${name}.log"
  if [[ ! -x ${script} ]]; then
    printf 'V6_SUITE_TEST_FAIL test=%s stage=missing_script\n' "${name}"
    failed=$((failed+1)); first_failed=${name}; first_stage=missing_script; suite_status=${statuses[$idx]}; break
  fi
  printf 'V6_SUITE_TEST_BEGIN test=%s\n' "${name}"
  env_args=()
  if [[ ${V6_QUICK:-0} == 1 ]]; then
    case ${name} in
      v6_smoke_module_lifecycle_100) env_args+=(V6_CYCLES=3) ;;
      v6_smoke_mkfs_mount_unmount_500) env_args+=(V6_CYCLES=3) ;;
      v6_smoke_full_v1_100) env_args+=(V6_CYCLES=3) ;;
      v6_smoke_v3_proof_30) env_args+=(V6_CYCLES=1) ;;
      v6_smoke_teardown_after_failure_100) env_args+=(V6_CYCLES=3) ;;
      v6_smoke_hash_manifest_integrity_100k) env_args+=(V6_FILE_COUNT=1000) ;;
      v6_smoke_directory_scale_1m) env_args+=(V6_ENTRY_COUNT=10000) ;;
      v6_smoke_small_file_pressure) env_args+=(V6_FILE_COUNT=5000) ;;
      v6_smoke_large_file_streaming) env_args+=(V6_LARGE_SIZE=128M) ;;
      v6_smoke_rename_delete_storm) env_args+=(V6_OPS=1000) ;;
      v6_smoke_parallel_writers) env_args+=(V6_PROCS=2 V6_FILES_PER_PROC=100) ;;
      v6_smoke_7_day_soak) env_args+=(V6_SOAK_HOURS=1) ;;
    esac
  fi
  if env "${env_args[@]}" "./${script}" >"${log}" 2>&1; then
    passed=$((passed+1)); printf 'V6_SUITE_TEST_PASS test=%s\n' "${name}"
  else
    failed=$((failed+1)); first_failed=${name}; first_stage=$(awk -F= '/^FAILED_STAGE=/{print $2; exit}' "$(awk -F'"' '/V6_ARTIFACTS_AT path=/{p=$2} END{print p}' "${log}")/summary.txt" 2>/dev/null || echo unknown); [[ -n ${first_stage} ]] || first_stage=unknown; suite_status=${statuses[$idx]}; printf 'V6_SUITE_TEST_FAIL test=%s stage=%s status=%s\n' "${name}" "${first_stage}" "${suite_status}"; break
  fi
done
if [[ ${failed} -gt 0 ]]; then skipped=$((${#names[@]} - passed - failed)); fi
r4_state "${ARTIFACT_DIR}/state-after.txt"
r4_cleanup "${ARTIFACT_DIR}"
r4_state "${ARTIFACT_DIR}/state-after-cleanup.txt"
r4_save_dmesg "${ARTIFACT_DIR}/dmesg-after.txt"
r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-after.txt" "${ARTIFACT_DIR}/dmesg-filtered.txt"
final_dmesg=0; r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-after.txt" || final_dmesg=1
silent=0; grep -R "^SILENT_CORRUPTION=1" "${ARTIFACT_DIR}"/*.log >/dev/null 2>&1 && silent=1
cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
V6_SMOKE_STATUS=${suite_status}
PASSED_TESTS=${passed}
FAILED_TESTS=${failed}
SKIPPED_TESTS=${skipped}
FIRST_FAILED_TEST=${first_failed}
FIRST_FAILED_STAGE=${first_stage}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
FINAL_MODULE_LOADED=$(r4_bool r4_module_loaded)
FINAL_KTXNMGRD_ALIVE=$(r4_bool r4_ktxnmgrd_alive)
FINAL_ENTD_ALIVE=$(r4_bool r4_entd_alive)
FINAL_LOOP_STUCK=$(r4_bool r4_any_reiser4_loop_exists)
FINAL_DMESG_DANGER=${final_dmesg}
FINAL_SILENT_CORRUPTION=${silent}
SUMMARY
printf 'V6_SMOKE_STATUS=%s PASSED_TESTS=%s FAILED_TESTS=%s SKIPPED_TESTS=%s\n' "${suite_status}" "${passed}" "${failed}" "${skipped}"
printf 'V6_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
[[ ${failed} -eq 0 ]]
