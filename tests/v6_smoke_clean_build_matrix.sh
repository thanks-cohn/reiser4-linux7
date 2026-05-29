#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_clean_build_matrix V6_CLEAN_BUILD_MATRIX_BEGIN
trap r4_v6_finish EXIT
KBUILD=${REISER4_KBUILD_DIR:-/lib/modules/$(uname -r)/build}
r4_log KERNEL "version=$(uname -r)"
r4_log HEADERS "path=${KBUILD}"
r4_log GCC "version=$(gcc --version 2>/dev/null | head -1 || echo missing)"
r4_log GIT "head=$(r4_git_head)"
find /lib/modules -maxdepth 2 -type d -name build -print >"${ARTIFACT_DIR}/available-header-trees.txt" 2>/dev/null || true
[[ -d ${KBUILD} && -f ${KBUILD}/Makefile ]] || r4_v6_fail_exit kernel_headers V6_CLEAN_BUILD_MATRIX_FAIL "missing kernel build dir ${KBUILD}"
make -C "${KBUILD}" M="${PWD}" clean >"${ARTIFACT_DIR}/make-clean.log" 2>&1 || r4_v6_fail_exit make_clean V6_CLEAN_BUILD_MATRIX_FAIL "make clean failed"
make -C "${KBUILD}" M="${PWD}" modules -j"$(nproc)" >"${ARTIFACT_DIR}/make-modules.log" 2>&1 || r4_v6_fail_exit make_modules V6_CLEAN_BUILD_MATRIX_FAIL "make modules failed"
[[ -f reiser4.ko ]] || r4_v6_fail_exit module_artifact V6_CLEAN_BUILD_MATRIX_FAIL missing_reiser4_ko=1
warn_count=$(grep -Eci 'warning:' "${ARTIFACT_DIR}/make-modules.log" 2>/dev/null || true)
module_size=$(stat -c '%s' reiser4.ko 2>/dev/null || echo 0)
module_sha=$(sha256sum reiser4.ko 2>/dev/null | awk '{print $1}' || echo unknown)
r4_log BUILD_DETAILS "warnings=${warn_count}" "module_size=${module_size}" "module_sha256=${module_sha}"
R4_SUMMARY_EXTRA="WARNINGS=${warn_count} MODULE_SIZE=${module_size} MODULE_SHA256=${module_sha}"
RESULT=PASS
printf 'V6_CLEAN_BUILD_MATRIX_PASS warnings=%s module_size=%s module_sha256=%s\n' "${warn_count}" "${module_size}" "${module_sha}"
