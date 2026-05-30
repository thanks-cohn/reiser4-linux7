#!/usr/bin/env bash
set -Eeuo pipefail

# Full V3 proof gate. V3 is not achieved unless this script prints FINAL PASS
# and the saved dmesg evidence is reviewed as clean.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE=${REISER4_V3_IMAGE:-/tmp/reiser4-v3.img}
MNT=${REISER4_V3_MNT:-/tmp/reiser4-v3-mnt}
SIZE=${REISER4_V3_SIZE:-2G}
MODULE=${REISER4_MODULE:-${ROOT_DIR}/reiser4.ko}
LOG_PREFIX=${LOG_PREFIX:-REISER4_V3}
LOG_DIR=${LOG_DIR:-${ROOT_DIR}/artifacts/reiser4-v3-proof-$(date -u +%Y%m%dT%H%M%SZ)}
RUN_LOG=${RUN_LOG:-${LOG_DIR}/run.log}
DMESG_LOG=${DMESG_LOG:-${LOG_DIR}/dmesg.final.log}
DMESG_PATTERN='BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free'
MODULE_LOADED=0
MOUNTED=0
LOOPDEV=""
FAILURES=0

mkdir -p "${LOG_DIR}"
exec > >(tee -a "${RUN_LOG}") 2>&1

cd "${ROOT_DIR}"

if [[ ${EUID} -eq 0 ]]; then
	SUDO=()
elif command -v sudo >/dev/null 2>&1; then
	SUDO=(sudo)
else
	echo "${LOG_PREFIX}: root or sudo is required" >&2
	exit 1
fi

run() { echo "+ $*"; "$@"; }
run_root() { echo "+ ${SUDO[*]} $*"; "${SUDO[@]}" "$@"; }

build_module() {
	local kbuild=${REISER4_KBUILD_DIR:-/lib/modules/$(uname -r)/build}
	if [[ -d ${kbuild} ]]; then
		run make -C "${kbuild}" M="${ROOT_DIR}" modules
	else
		echo "${LOG_PREFIX}: kernel build directory not found: ${kbuild}" >&2
		return 1
	fi
}

clear_dmesg_if_permitted() {
	echo "+ ${SUDO[*]} dmesg -C"
	if "${SUDO[@]}" dmesg -C >/dev/null 2>&1; then
		echo "${LOG_PREFIX}: cleared dmesg for V3 proof window"
	else
		echo "${LOG_PREFIX}: WARNING: unable to clear dmesg; scan may include older messages"
	fi
}

dump_dmesg() {
	echo "${LOG_PREFIX}: dmesg tail follows" >&2
	"${SUDO[@]}" dmesg --ctime --color=never 2>/dev/null | tail -500 >&2 || true
}

capture_dmesg() {
	"${SUDO[@]}" dmesg --ctime --color=never >"${DMESG_LOG}" 2>&1 || true
	echo "${LOG_PREFIX}: dmesg saved to ${DMESG_LOG}"
}

scan_dmesg() {
	capture_dmesg
	if grep -Eiq "${DMESG_PATTERN}" "${DMESG_LOG}"; then
		echo "${LOG_PREFIX}: dmesg scan found dangerous kernel text: ${DMESG_PATTERN}" >&2
		grep -Ein "${DMESG_PATTERN}" "${DMESG_LOG}" | tail -100 >&2 || true
		return 1
	fi
}

fail() {
	echo "${LOG_PREFIX}: FAIL: $*" >&2
	dump_dmesg
	exit 1
}

cleanup() {
	set +e
	if [[ ${MOUNTED} -eq 1 ]]; then
		"${SUDO[@]}" umount "${MNT}" >/dev/null 2>&1
	fi
	if [[ -n ${LOOPDEV} ]]; then
		"${SUDO[@]}" losetup -d "${LOOPDEV}" >/dev/null 2>&1
	fi
	if [[ ${MODULE_LOADED} -eq 1 ]]; then
		"${SUDO[@]}" rmmod reiser4 >/dev/null 2>&1
	fi
}
trap cleanup EXIT
trap 'fail "command failed at line ${LINENO}"' ERR

summary_step() {
	local name=$1
	shift
	echo "${LOG_PREFIX}: START ${name}"
	if "$@"; then
		echo "${LOG_PREFIX}: PASS ${name}"
	else
		echo "${LOG_PREFIX}: FAIL ${name}" >&2
		FAILURES=$((FAILURES + 1))
		return 1
	fi
}

if [[ ! -e ${MODULE} ]]; then
	build_module || fail "build failed and ${MODULE} does not exist"
fi
[[ -e ${MODULE} ]] || fail "missing module ${MODULE}"
command -v mkfs.reiser4 >/dev/null 2>&1 || fail "mkfs.reiser4 not found in PATH"
command -v losetup >/dev/null 2>&1 || fail "losetup not found in PATH"

run uname -a
if command -v mkfs.reiser4 >/dev/null 2>&1; then
	mkfs.reiser4 -V 2>&1 | head -5 || true
fi
if command -v fsck.reiser4 >/dev/null 2>&1; then
	fsck.reiser4 -V 2>&1 | head -5 || true
fi
clear_dmesg_if_permitted

summary_step "script-v1-smoke" scripts/reiser4-v1-smoke.sh || true
scan_dmesg || FAILURES=$((FAILURES + 1))

LOG_DIR="${LOG_DIR}/mkdir-regression" summary_step "script-v3-mkdir-regression" scripts/reiser4-v3-mkdir-regression.sh || true
scan_dmesg || FAILURES=$((FAILURES + 1))

run_root umount "${MNT}" 2>/dev/null || true
run_root rmmod reiser4 2>/dev/null || true
run rm -f "${IMAGE}"
run mkdir -p "${MNT}"
run truncate -s "${SIZE}" "${IMAGE}"
echo "+ mkfs.reiser4 -y -f ${IMAGE}"
"${SUDO[@]}" mkfs.reiser4 -y -f "${IMAGE}"
run_root insmod "${MODULE}"
MODULE_LOADED=1
LOOPDEV="$("${SUDO[@]}" losetup --find --show "${IMAGE}")"
echo "${LOG_PREFIX}: loopdev=${LOOPDEV}"
run_root mount -t reiser4 "${LOOPDEV}" "${MNT}"
MOUNTED=1

# Nested directories and many-small-files test.
run_root mkdir -p "${MNT}/small-files"
for depth in $(seq 1 40); do
	path="${MNT}/nested"
	for n in $(seq 1 "${depth}"); do
		path="${path}/d${n}"
	done
	run_root mkdir -p "${path}"
	printf 'depth=%s\n' "${depth}" | "${SUDO[@]}" tee "${path}/marker" >/dev/null
	run_root test -s "${path}/marker"
done
for i in $(seq 1 2000); do
	printf 'small-file=%s\n' "${i}" | "${SUDO[@]}" tee "${MNT}/small-files/file-${i}" >/dev/null
done
run_root test -f "${MNT}/small-files/file-2000"

# Rename/delete test.
run_root mkdir -p "${MNT}/rename-delete"
for i in $(seq 1 500); do
	printf 'rename-delete=%s\n' "${i}" | "${SUDO[@]}" tee "${MNT}/rename-delete/item-${i}" >/dev/null
	run_root mv "${MNT}/rename-delete/item-${i}" "${MNT}/rename-delete/item-${i}.renamed"
done
for i in $(seq 1 250); do
	run_root rm "${MNT}/rename-delete/item-${i}.renamed"
done
run_root test -f "${MNT}/rename-delete/item-500.renamed"
run_root test ! -e "${MNT}/rename-delete/item-1.renamed"

# Medium file to ensure the proof is not directory-only.
run_root mkdir -p "${MNT}/medium-files"
run_root dd if=/dev/zero of="${MNT}/medium-files/medium.bin" bs=1M count=64 status=none
run_root test -s "${MNT}/medium-files/medium.bin"

# Repeated remount verification.
for cycle in $(seq 1 3); do
	echo "${LOG_PREFIX}: remount verification cycle ${cycle}"
	run_root sync
	run_root umount "${MNT}"
	MOUNTED=0
	run_root mount -t reiser4 "${LOOPDEV}" "${MNT}"
	MOUNTED=1
	run_root test -f "${MNT}/small-files/file-2000"
	run_root test -s "${MNT}/medium-files/medium.bin"
	run_root test -f "${MNT}/rename-delete/item-500.renamed"
	run_root test ! -e "${MNT}/rename-delete/item-1.renamed"
done

run_root sync
run_root umount "${MNT}"
MOUNTED=0

if command -v fsck.reiser4 >/dev/null 2>&1; then
	run_root fsck.reiser4 -y "${LOOPDEV}" || fail "fsck.reiser4 failed"
elif command -v reiser4fsck >/dev/null 2>&1; then
	run_root reiser4fsck -y "${LOOPDEV}" || fail "reiser4fsck failed"
else
	echo "${LOG_PREFIX}: fsck/reiser4progs sanity skipped: no fsck.reiser4 or reiser4fsck found"
fi

run_root losetup -d "${LOOPDEV}"
LOOPDEV=""
run_root rmmod reiser4
MODULE_LOADED=0
scan_dmesg || FAILURES=$((FAILURES + 1))

if (( FAILURES == 0 )); then
	echo "${LOG_PREFIX}: FINAL PASS"
else
	echo "${LOG_PREFIX}: FINAL FAIL failures=${FAILURES}" >&2
	exit 1
fi
