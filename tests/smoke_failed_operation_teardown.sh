#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_failed_operation_teardown SMOKE_FAILED_OPERATION_TEARDOWN
trap r4_finish_test EXIT
FAIL_CRUMB=SMOKE_TEARDOWN_AFTER_FAILURE_FAIL

r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
if ! r4_mount_new_image "${IMAGE}" "${MNT}" "${SIZE}"; then r4_fail_exit setup ${FAIL_CRUMB} 'mkfs/insmod/mount setup failed'; fi
printf 'SMOKE_MOUNT_PASS\n'

if out=$(mkdir "${MNT}/expected-fail-dir" 2>&1); then
	if cat "${MNT}/definitely-not-present" >/dev/null 2>"${ARTIFACT_DIR}/expected-failure.err"; then
		r4_fail_exit deliberate_failure SMOKE_TEARDOWN_AFTER_FAILURE_FAIL no_expected_failure_observed
	fi
	printf 'SMOKE_EXPECTED_FAILURE_OBSERVED operation="missing_file" error="%s"\n' "$(r4_quote_msg "$(cat "${ARTIFACT_DIR}/expected-failure.err")")"
else
	printf 'SMOKE_EXPECTED_FAILURE_OBSERVED operation="mkdir" error="%s"\n' "$(r4_quote_msg "${out}")"
fi
sync || true
umount "${MNT}" >/dev/null 2>&1 || true
r4_cleanup "${ARTIFACT_DIR}"
if r4_module_loaded || r4_ktxnmgrd_alive || r4_entd_alive || r4_any_reiser4_loop_exists; then
	FAILED_STAGE=teardown
	printf 'SMOKE_TEARDOWN_AFTER_FAILURE_FAIL\n'
	exit 1
fi
RESULT=PASS
printf 'SMOKE_TEARDOWN_AFTER_FAILURE_PASS\n'
