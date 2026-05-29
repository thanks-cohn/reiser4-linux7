#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_teardown_after_failure_100 V6_TEARDOWN_AFTER_FAILURE_100_BEGIN
trap r4_v6_finish EXIT
CYCLES=${V6_CYCLES:-100}; MNT=/tmp/reiser4-v6-failure-mnt
r4_v6_require_root_and_tools V6_TEARDOWN_AFTER_FAILURE_CYCLE_FAIL
for cycle in $(seq 1 "${CYCLES}"); do
  mkdir -p "${MNT}"
  if r4_module_loaded; then rmmod reiser4 >/dev/null 2>&1 || true; fi
  if ! r4_module_loaded; then insmod ./reiser4.ko || { printf 'V6_TEARDOWN_AFTER_FAILURE_CYCLE_FAIL cycle=%s stage=insmod\n' "$cycle"; FAILED_STAGE="insmod_${cycle}"; exit 1; }; fi
  if mount -t reiser4 -o loop "/no/such/reiser4-v6-${cycle}.img" "${MNT}" >"${ARTIFACT_DIR}/expected-failure-${cycle}.log" 2>&1; then
    printf 'V6_TEARDOWN_AFTER_FAILURE_CYCLE_FAIL cycle=%s stage=expected_failure_missing\n' "$cycle"; FAILED_STAGE="expected_failure_${cycle}"; exit 1
  fi
  printf 'V6_EXPECTED_FAILURE_OBSERVED cycle=%s failure_type=missing_loopback_image\n' "$cycle"
  r4_cleanup "${ARTIFACT_DIR}"
  if r4_module_loaded || r4_ktxnmgrd_alive || r4_entd_alive || r4_any_reiser4_loop_exists; then
    printf 'V6_TEARDOWN_AFTER_FAILURE_CYCLE_FAIL cycle=%s stage=cleanup\n' "$cycle"; FAILED_STAGE="cleanup_${cycle}"; exit 1
  fi
  printf 'V6_TEARDOWN_AFTER_FAILURE_CYCLE_PASS cycle=%s\n' "$cycle"
done
RESULT=PASS
printf 'V6_TEARDOWN_AFTER_FAILURE_100_PASS cycles=%s\n' "${CYCLES}"
