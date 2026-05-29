#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_module_lifecycle_100 V6_MODULE_LIFECYCLE_100_BEGIN
trap r4_v6_finish EXIT
CYCLES=${V6_CYCLES:-100}
[[ ${EUID} -eq 0 ]] || r4_v6_fail_exit preflight V6_MODULE_LIFECYCLE_CYCLE_FAIL root_required=1
[[ -e ./reiser4.ko ]] || r4_v6_fail_exit preflight V6_MODULE_LIFECYCLE_CYCLE_FAIL missing_reiser4_ko=1
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_MODULE_LIFECYCLE_CYCLE_FAIL preexisting_dirty_state=1
for cycle in $(seq 1 "${CYCLES}"); do
  r4_state "${ARTIFACT_DIR}/state-cycle-${cycle}-before.txt"
  if ! out=$(insmod ./reiser4.ko 2>&1); then printf 'V6_MODULE_LIFECYCLE_CYCLE_FAIL cycle=%s stage=insmod error="%s"\n' "$cycle" "$(r4_quote_msg "$out")"; FAILED_STAGE="insmod_${cycle}"; exit 1; fi
  grep reiser4 /proc/filesystems >"${ARTIFACT_DIR}/proc-filesystems-cycle-${cycle}.txt" 2>&1 || true
  lsmod >"${ARTIFACT_DIR}/lsmod-cycle-${cycle}-loaded.txt" 2>&1 || true
  if ! out=$(rmmod reiser4 2>&1); then printf 'V6_MODULE_LIFECYCLE_CYCLE_FAIL cycle=%s stage=rmmod error="%s"\n' "$cycle" "$(r4_quote_msg "$out")"; printf 'V6_RMMOD_FAIL module_ref_stuck=%s\n' "$(r4_module_refcount)"; FAILED_STAGE="rmmod_${cycle}"; exit 1; fi
  lsmod >"${ARTIFACT_DIR}/lsmod-cycle-${cycle}-after.txt" 2>&1 || true
  r4_has_dmesg_danger || { printf 'V6_MODULE_LIFECYCLE_CYCLE_FAIL cycle=%s stage=dmesg\n' "$cycle"; FAILED_STAGE="dmesg_${cycle}"; exit 1; }
  printf 'V6_MODULE_LIFECYCLE_CYCLE_PASS cycle=%s\n' "$cycle"
done
RESULT=PASS
printf 'V6_MODULE_LIFECYCLE_100_PASS cycles=%s\n' "${CYCLES}"
