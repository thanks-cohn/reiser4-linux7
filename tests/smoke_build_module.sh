#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_build_module SMOKE_BUILD_MODULE
trap r4_finish_test EXIT
KBUILD=${REISER4_KBUILD_DIR:-/lib/modules/$(uname -r)/build}
r4_log KERNEL "uname=\"$(uname -a)\""
r4_log GCC "version=\"$(gcc --version 2>/dev/null | head -1 || echo missing)\""
r4_log GIT "head=$(r4_git_head)"
[[ -d ${KBUILD} && -f ${KBUILD}/Makefile ]] || r4_fail_exit kernel_headers SMOKE_BUILD_MODULE_FAIL "missing kernel build dir ${KBUILD}"
make -C "${KBUILD}" M="${PWD}" clean >"${ARTIFACT_DIR}/make-clean.log" 2>&1 || r4_fail_exit make_clean SMOKE_BUILD_MODULE_FAIL "make clean failed; see ${ARTIFACT_DIR}/make-clean.log"
make -C "${KBUILD}" M="${PWD}" modules -j"$(nproc)" >"${ARTIFACT_DIR}/make-modules.log" 2>&1 || r4_fail_exit make_modules SMOKE_BUILD_MODULE_FAIL "make modules failed; see ${ARTIFACT_DIR}/make-modules.log"
[[ -f reiser4.ko ]] || r4_fail_exit module_artifact SMOKE_BUILD_MODULE_FAIL 'reiser4.ko missing after build'
warn_count=$(grep -Eci 'warning:' "${ARTIFACT_DIR}/make-modules.log" 2>/dev/null || true)
size=$(stat -c '%s' reiser4.ko 2>/dev/null || echo 0)
r4_log BUILD_DETAILS "warnings=${warn_count}" "module_size=${size}"
RESULT=PASS
printf 'SMOKE_BUILD_MODULE_PASS warnings=%s module_size=%s\n' "${warn_count}" "${size}"
