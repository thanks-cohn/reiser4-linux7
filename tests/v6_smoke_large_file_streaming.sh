#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_large_file_streaming V6_LARGE_FILE_STREAMING_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-2G}; MNT=/tmp/v6_smoke_large_file_streaming-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_large_file_streaming.img"
r4_v6_require_root_and_tools V6_LARGE_FILE_STREAMING_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_LARGE_FILE_STREAMING_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_LARGE_FILE_STREAMING_FAIL mount_failed=1

LARGE=${V6_LARGE_SIZE:-1G}; /usr/bin/time -o "${ARTIFACT_DIR}/write-time.txt" truncate -s "${LARGE}" "${MNT}/large.bin" || r4_v6_fail_exit write V6_LARGE_FILE_STREAMING_FAIL write_failed=1
sync; sha256sum "${MNT}/large.bin" >"${ARTIFACT_DIR}/large.sha256.before"; stat -c 'size=%s' "${MNT}/large.bin" >"${ARTIFACT_DIR}/large-stat.txt"
r4_v6_unmount_image "${IMAGE}" "${MNT}" || r4_v6_fail_exit unmount V6_LARGE_FILE_STREAMING_FAIL unmount_failed=1
insmod ./reiser4.ko 2>/dev/null || true; mount -t reiser4 -o loop "${IMAGE}" "${MNT}" || r4_v6_fail_exit remount V6_LARGE_FILE_STREAMING_FAIL remount_failed=1
sha256sum "${MNT}/large.bin" >"${ARTIFACT_DIR}/large.sha256.after"; cmp -s "${ARTIFACT_DIR}/large.sha256.before" "${ARTIFACT_DIR}/large.sha256.after" || { SILENT_CORRUPTION=1; r4_v6_fail_exit verify V6_LARGE_FILE_STREAMING_FAIL hash_mismatch=1; }
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_LARGE_FILE_STREAMING_PASS
'
