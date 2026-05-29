#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_v3_proof_30 V6_V3_PROOF_30_BEGIN
trap r4_v6_finish EXIT
CYCLES=${V6_CYCLES:-30}
[[ -x tests/prove_reiser4_v3.sh ]] || { printf 'V6_V3_PROOF_30_FAIL missing_prove_reiser4_v3=1\n'; FAILED_STAGE=missing_prove_reiser4_v3; exit 1; }
for cycle in $(seq 1 "${CYCLES}"); do
  if V3_CYCLE=${cycle} ./tests/prove_reiser4_v3.sh >"${ARTIFACT_DIR}/v3-proof-cycle-${cycle}.log" 2>&1; then
    printf 'V6_V3_PROOF_CYCLE_PASS cycle=%s\n' "$cycle"
  else
    printf 'V6_V3_PROOF_CYCLE_FAIL cycle=%s\n' "$cycle"; FAILED_STAGE="v3_proof_${cycle}"; exit 1
  fi
  r4_has_dmesg_danger || { printf 'V6_V3_PROOF_CYCLE_FAIL cycle=%s stage=dmesg\n' "$cycle"; FAILED_STAGE="dmesg_${cycle}"; exit 1; }
done
RESULT=PASS
printf 'V6_V3_PROOF_30_PASS cycles=%s\n' "${CYCLES}"
