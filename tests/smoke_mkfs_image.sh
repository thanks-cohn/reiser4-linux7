#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_mkfs_image SMOKE_MKFS_IMAGE
trap r4_finish_test EXIT
command -v mkfs.reiser4 >/dev/null 2>&1 || r4_fail_exit preflight SMOKE_MKFS_IMAGE_FAIL missing_mkfs_reiser4
IMAGE=${ARTIFACT_DIR}/mkfs-image.img; SIZE=${REISER4_SMOKE_SIZE:-128M}
r4_log MKFS_VERSION "version=\"$(mkfs.reiser4 -V 2>&1 | head -1 || true)\""
r4_log IMAGE "path=${IMAGE}" "size=${SIZE}"
truncate -s "${SIZE}" "${IMAGE}" || r4_fail_exit truncate SMOKE_MKFS_IMAGE_FAIL "truncate failed"
set +e
mkfs.reiser4 -y -f "${IMAGE}" >"${ARTIFACT_DIR}/mkfs.log" 2>&1
mkfs_rc=$?
set -u
r4_log MKFS_EXIT "exit_code=${mkfs_rc}"
grep -Ei 'block|uuid' "${ARTIFACT_DIR}/mkfs.log" >"${ARTIFACT_DIR}/mkfs-selected.log" 2>/dev/null || true
[[ ${mkfs_rc} -eq 0 ]] || r4_fail_exit mkfs SMOKE_MKFS_IMAGE_FAIL "$(cat "${ARTIFACT_DIR}/mkfs.log")"
RESULT=PASS
printf 'SMOKE_MKFS_IMAGE_PASS image="%s" exit_code=%s\n' "${IMAGE}" "${mkfs_rc}"
