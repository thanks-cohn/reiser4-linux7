#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_dmesg_cleanliness SMOKE_DMESG_CLEANLINESS
trap r4_finish_test EXIT
r4_save_dmesg "${ARTIFACT_DIR}/dmesg-full.log"
r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-full.log" "${ARTIFACT_DIR}/dmesg-filtered.txt"
if ! r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-full.log"; then FAILED_STAGE=dmesg; printf 'SMOKE_DMESG_DANGER\n'; exit 1; fi
RESULT=PASS
printf 'SMOKE_DMESG_CLEANLINESS_PASS\n'
