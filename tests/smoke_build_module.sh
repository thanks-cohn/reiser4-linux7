#!/usr/bin/env bash
set -u -o pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

TEST_NAME=smoke_build_module
ARTIFACT_DIR=$(r4_make_artifact_dir "${TEST_NAME}")
R4_ARTIFACT_DIR=${ARTIFACT_DIR}
RESULT=FAIL
FAILED_STAGE=none
DMESG_DANGER=0
KBUILD=${REISER4_KBUILD_DIR:-/lib/modules/$(uname -r)/build}

finish() {
	local rc=$?
	r4_save_dmesg "${ARTIFACT_DIR}" before-cleanup
	r4_try_cleanup "${ARTIFACT_DIR}"
	if r4_dmesg_scan final >"${ARTIFACT_DIR}/dmesg-final-scan.txt" 2>&1; then DMESG_DANGER=0; else DMESG_DANGER=1; fi
	cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
TEST=${TEST_NAME}
RESULT=${RESULT}
FAILED_STAGE=${FAILED_STAGE}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
KBUILD=${KBUILD}
MODULE_EXISTS=$([[ -e reiser4.ko ]] && echo 1 || echo 0)
DMESG_DANGER=${DMESG_DANGER}
SUMMARY
	printf 'SMOKE_ARTIFACTS_AT %s\n' "${ARTIFACT_DIR}"
	printf 'REISER4_SMOKE_END test=%s result=%s failed_stage=%s\n' "${TEST_NAME}" "${RESULT}" "${FAILED_STAGE}"
	exit ${rc}
}
trap finish EXIT

printf 'REISER4_SMOKE_BEGIN test=%s artifact_dir=%s\n' "${TEST_NAME}" "${ARTIFACT_DIR}"
r4_save_state "${ARTIFACT_DIR}" before-test
r4_save_dmesg "${ARTIFACT_DIR}" before-test

if [[ ! -d ${KBUILD} ]]; then
	FAILED_STAGE=kernel_headers
	printf 'SMOKE_BUILD_FAIL stage=kernel_headers path="%s"\n' "${KBUILD}"
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
fi
if [[ ! -f ${KBUILD}/Makefile ]]; then
	FAILED_STAGE=kernel_headers_makefile
	printf 'SMOKE_BUILD_FAIL stage=kernel_headers_makefile path="%s/Makefile"\n' "${KBUILD}"
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
fi

if ! make -C "${KBUILD}" M="${PWD}" clean >"${ARTIFACT_DIR}/make-clean.log" 2>&1; then
	FAILED_STAGE=make_clean
	printf 'SMOKE_BUILD_FAIL stage=make_clean log="%s"\n' "${ARTIFACT_DIR}/make-clean.log"
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
fi
if ! make -C "${KBUILD}" M="${PWD}" modules -j"$(nproc)" >"${ARTIFACT_DIR}/make-modules.log" 2>&1; then
	FAILED_STAGE=make_modules
	printf 'SMOKE_BUILD_FAIL stage=make_modules log="%s"\n' "${ARTIFACT_DIR}/make-modules.log"
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
fi
if [[ ! -e reiser4.ko ]]; then
	FAILED_STAGE=module_artifact
	printf 'SMOKE_BUILD_FAIL stage=module_artifact path="reiser4.ko"\n'
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
fi

if strings reiser4.ko 2>/dev/null | grep -q 'BUMRUSH26'; then
	printf 'SMOKE_BUILD_INSTRUMENTATION_PRESENT pattern=BUMRUSH26\n'
else
	printf 'SMOKE_BUILD_INSTRUMENTATION_ABSENT pattern=BUMRUSH26\n'
fi

RESULT=PASS
printf 'SMOKE_BUILD_PASS module="reiser4.ko"\n'
exit 0
