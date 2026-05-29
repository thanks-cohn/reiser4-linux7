#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_directory_scale_1m V6_DIRECTORY_SCALE_1M_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-4G}; MNT=/tmp/v6_smoke_directory_scale_1m-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_directory_scale_1m.img"
r4_v6_require_root_and_tools V6_DIRECTORY_SCALE_1M_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_DIRECTORY_SCALE_1M_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_DIRECTORY_SCALE_1M_FAIL mount_failed=1

COUNT=${V6_ENTRY_COUNT:-1000000}; mkdir -p "${MNT}/scale"
start=$(date +%s); for i in $(seq 1 "${COUNT}"); do mkdir -p "${MNT}/scale/d$(printf '%07d' "$i")" || r4_v6_fail_exit create V6_DIRECTORY_SCALE_1M_FAIL "mkdir failed at ${i}"; done; end=$(date +%s)
printf 'V6_DIRECTORY_SCALE_CREATE_PASS count=%s seconds=%s\n' "${COUNT}" "$((end-start))"
/usr/bin/time -o "${ARTIFACT_DIR}/list-time.txt" find "${MNT}/scale" -maxdepth 1 -type d >/dev/null || r4_v6_fail_exit list V6_DIRECTORY_SCALE_1M_FAIL list_failed=1
printf 'V6_DIRECTORY_SCALE_LIST_PASS\n'
/usr/bin/time -o "${ARTIFACT_DIR}/stat-time.txt" bash -c 'find "$1" -maxdepth 1 -type d -exec stat {} \; >/dev/null' _ "${MNT}/scale" || r4_v6_fail_exit stat V6_DIRECTORY_SCALE_1M_FAIL stat_failed=1
printf 'V6_DIRECTORY_SCALE_STAT_PASS\n'
/usr/bin/time -o "${ARTIFACT_DIR}/delete-time.txt" rm -rf "${MNT}/scale" || r4_v6_fail_exit delete V6_DIRECTORY_SCALE_1M_FAIL delete_failed=1
printf 'V6_DIRECTORY_SCALE_DELETE_PASS\n'
r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_DIRECTORY_SCALE_1M_PASS
'
