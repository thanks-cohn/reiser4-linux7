#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${1:-${ROOT_DIR}/artifacts/failure-${TIMESTAMP}}"
LAST_TEST_LOG="${LAST_TEST_LOG:-}"

mkdir -p "${OUT_DIR}"

run_capture() {
	local target=$1
	shift
	{
		printf '+ %s\n' "$*"
		"$@"
	} >"${OUT_DIR}/${target}" 2>&1 || true
}

run_shell_capture() {
	local target=$1
	local command=$2
	{
		printf '+ %s\n' "${command}"
		bash -o pipefail -c "${command}"
	} >"${OUT_DIR}/${target}" 2>&1 || true
}

"${ROOT_DIR}/tools/reiser4_env_report.sh" >"${OUT_DIR}/env-report.log" 2>&1 || true
run_capture dmesg.log dmesg -T
run_capture git-commit.log git rev-parse HEAD
run_capture git-status-short.log git status --short
run_capture mount-state.log mount
run_capture loop-devices.log losetup -a
run_shell_capture module-state.log 'lsmod | grep -E "(^| )reiser4" || true'
run_shell_capture filesystems.log 'grep reiser4 /proc/filesystems || true'

if [[ -n "${LAST_TEST_LOG}" && -f "${LAST_TEST_LOG}" ]]; then
	cp -a "${LAST_TEST_LOG}" "${OUT_DIR}/last-test.log"
else
	{
		echo "LAST_TEST_LOG was not set or did not point to a file."
		echo "LAST_TEST_LOG=${LAST_TEST_LOG}"
	} >"${OUT_DIR}/last-test.log"
fi

printf 'failure bundle: %s\n' "${OUT_DIR}"
