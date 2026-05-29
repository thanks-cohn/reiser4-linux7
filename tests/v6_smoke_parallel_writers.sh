#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_v6_init v6_smoke_parallel_writers V6_PARALLEL_WRITERS_BEGIN
trap r4_v6_finish EXIT
SIZE=${V6_IMAGE_SIZE:-1G}; MNT=/tmp/v6_smoke_parallel_writers-mnt; IMAGE="${ARTIFACT_DIR}/v6_smoke_parallel_writers.img"
r4_v6_require_root_and_tools V6_PARALLEL_WRITERS_FAIL
r4_require_clean_start "${ARTIFACT_DIR}" || r4_v6_fail_exit clean_start V6_PARALLEL_WRITERS_FAIL preexisting_dirty_state=1
r4_v6_mount_image "${IMAGE}" "${MNT}" "${SIZE}" || r4_v6_fail_exit mount V6_PARALLEL_WRITERS_FAIL mount_failed=1

PROCS=${V6_PROCS:-8}; FILES=${V6_FILES_PER_PROC:-1000}; mkdir -p "${MNT}/parallel"; failures="${ARTIFACT_DIR}/parallel-failures.txt"; : >"$failures"
for p in $(seq 1 "${PROCS}"); do (for i in $(seq 1 "${FILES}"); do d="${MNT}/parallel/p${p}"; mkdir -p "$d"; printf 'proc=%s file=%s\n' "$p" "$i" >"$d/file-$i" || echo "write p=$p i=$i" >>"$failures"; grep -q "proc=${p}" "$d/file-$i" || echo "read p=$p i=$i" >>"$failures"; done) & done
wait
[[ ! -s $failures ]] || r4_v6_fail_exit workload V6_PARALLEL_WRITERS_FAIL "failures recorded"
r4_hash_manifest "${MNT}" "${ARTIFACT_DIR}/manifest.tsv"; bytes=$(du -sb "${MNT}/parallel" | awk '{print $1}'); r4_log PARALLEL "procs=${PROCS}" "files_per_proc=${FILES}" "bytes=${bytes}"
sync; r4_v6_unmount_image "${IMAGE}" "${MNT}" || true

RESULT=PASS
printf 'V6_PARALLEL_WRITERS_PASS
'
