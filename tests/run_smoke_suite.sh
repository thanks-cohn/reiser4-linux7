#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
source tests/lib/reiser4_test_lib.sh

TEST_NAME=run_smoke_suite
ARTIFACT_DIR=$(r4_make_artifact_dir "${TEST_NAME}")
RESULT=PASS
FAILED_STAGE=none

printf 'REISER4_SMOKE_BEGIN test=%s artifact_dir=%s\n' "${TEST_NAME}" "${ARTIFACT_DIR}"
r4_save_state "${ARTIFACT_DIR}" before-test
r4_save_dmesg "${ARTIFACT_DIR}" before-test

run_one() {
	local name=$1
	local script=$2
	printf 'REISER4_SUITE_RUN test=%s script=%s\n' "${name}" "${script}"
	if "${script}" >"${ARTIFACT_DIR}/${name}.log" 2>&1; then
		cat "${ARTIFACT_DIR}/${name}.log"
		printf 'REISER4_SUITE_PASS test=%s\n' "${name}"
		return 0
	fi
	local rc=$?
	cat "${ARTIFACT_DIR}/${name}.log"
	printf 'REISER4_SUITE_FAIL test=%s rc=%s\n' "${name}" "${rc}"
	return "${rc}"
}

if ! run_one smoke_build_module tests/smoke_build_module.sh; then
	RESULT=FAIL; FAILED_STAGE=smoke_build_module
	printf 'REISER4_SUITE_STOP reason=build_module_failed\n'
elif ! run_one smoke_module_lifecycle tests/smoke_module_lifecycle.sh; then
	RESULT=FAIL; FAILED_STAGE=smoke_module_lifecycle
	printf 'REISER4_SUITE_STOP reason=module_lifecycle_failed skip=filesystem_mutation_tests\n'
elif ! run_one smoke_mkfs_mount_unmount tests/smoke_mkfs_mount_unmount.sh; then
	RESULT=FAIL; FAILED_STAGE=smoke_mkfs_mount_unmount
	printf 'REISER4_SUITE_STOP reason=mount_unmount_failed skip=file_tests\n'
elif ! run_one smoke_regular_file_rw tests/smoke_regular_file_rw.sh; then
	RESULT=FAIL; FAILED_STAGE=smoke_regular_file_rw
	printf 'REISER4_SUITE_STOP reason=regular_file_rw_failed skip=v1\n'
else
	if ! run_one smoke_mkdir_only tests/smoke_mkdir_only.sh; then
		printf 'REISER4_SUITE_KNOWN_BLOCKER test=smoke_mkdir_only breadcrumb=SMOKE_MKDIR_FAIL\n'
	fi
	if ! run_one smoke_teardown_after_failure tests/smoke_teardown_after_failure.sh; then
		RESULT=FAIL; FAILED_STAGE=smoke_teardown_after_failure
		printf 'REISER4_SUITE_TEARDOWN_RISK test=smoke_teardown_after_failure\n'
	fi
	if [[ ${RESULT} == PASS ]]; then
		if ! run_one smoke_reiser4_v1 tests/smoke_reiser4_v1.sh; then
			RESULT=FAIL; FAILED_STAGE=smoke_reiser4_v1
			printf 'REISER4_SUITE_V1_NOT_PASSED test=smoke_reiser4_v1\n'
		fi
	else
		printf 'REISER4_SUITE_SKIP test=smoke_reiser4_v1 reason=teardown_after_failure_failed\n'
	fi
fi

if [[ ${RESULT} != PASS ]]; then
	r4_save_state "${ARTIFACT_DIR}" after-failure
fi
r4_save_dmesg "${ARTIFACT_DIR}" before-cleanup
r4_save_state "${ARTIFACT_DIR}" after-cleanup
r4_save_dmesg "${ARTIFACT_DIR}" after-cleanup
cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
TEST=${TEST_NAME}
RESULT=${RESULT}
FAILED_STAGE=${FAILED_STAGE}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
DMESG_DANGER=$(if r4_dmesg_scan final >/dev/null 2>&1; then echo 0; else echo 1; fi)
SUMMARY
printf 'SMOKE_ARTIFACTS_AT %s\n' "${ARTIFACT_DIR}"
printf 'REISER4_SMOKE_END test=%s result=%s failed_stage=%s\n' "${TEST_NAME}" "${RESULT}" "${FAILED_STAGE}"
[[ ${RESULT} == PASS ]]
