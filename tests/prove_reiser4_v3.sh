#!/usr/bin/env bash
set -Eeuo pipefail

V2_LOOPS=${REISER4_V3_STRESS_LOOPS:-1000}
IMAGE=${REISER4_V3_IMAGE:-/tmp/reiser4-v3.img}
MNT=${REISER4_V3_MNT:-/tmp/reiser4-v3-mnt}
SIZE=${REISER4_V3_SIZE:-2G}
MODULE=${REISER4_MODULE:-./reiser4.ko}
LOG_PREFIX=${LOG_PREFIX:-REISER4_V3}
MODULE_LOADED=0
MOUNTED=0
FAILURES=0

if [[ ${EUID} -eq 0 ]]; then
	SUDO=()
elif command -v sudo >/dev/null 2>&1; then
	SUDO=(sudo)
else
	echo "${LOG_PREFIX}: root or sudo is required" >&2
	exit 1
fi

run() { echo "+ $*" >&2; "$@"; }
run_root() { echo "+ ${SUDO[*]} $*" >&2; "${SUDO[@]}" "$@"; }

build_module() {
	local kbuild=${REISER4_KBUILD_DIR:-/lib/modules/$(uname -r)/build}
	if [[ -d ${kbuild} ]]; then
		run make -C "${kbuild}" M="$(pwd)" modules
	else
		echo "${LOG_PREFIX}: kernel build directory not found: ${kbuild}" >&2
		return 1
	fi
}

dump_dmesg() {
	echo "${LOG_PREFIX}: dmesg tail follows" >&2
	"${SUDO[@]}" dmesg --ctime --color=never 2>/dev/null | tail -500 >&2 || true
}

scan_dmesg() {
	local pattern='BUG|Oops|panic|WARNING|null pointer|NULL pointer|use-after-free|KASAN|general protection fault'
	if "${SUDO[@]}" dmesg --color=never 2>/dev/null | grep -Eiq "${pattern}"; then
		echo "${LOG_PREFIX}: dmesg scan found dangerous kernel text" >&2
		"${SUDO[@]}" dmesg --ctime --color=never 2>/dev/null | grep -Ein "${pattern}" | tail -100 >&2 || true
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

echo "${LOG_PREFIX}: kernel=$(uname -r)"
if command -v mkfs.reiser4 >/dev/null 2>&1; then
	mkfs.reiser4 -V 2>&1 | head -5 || true
fi

summary_step "v1-smoke" tests/smoke_reiser4_v1.sh
summary_step "v2-stress-${V2_LOOPS}" tests/stress_reiser4_v2.sh "${V2_LOOPS}"

run_root umount "${MNT}" 2>/dev/null || true
run_root rmmod reiser4 2>/dev/null || true
run rm -f "${IMAGE}"
run mkdir -p "${MNT}"
run truncate -s "${SIZE}" "${IMAGE}"
run_root mkfs.reiser4 -f "${IMAGE}"
run_root insmod "${MODULE}"
MODULE_LOADED=1
run_root mount -t reiser4 -o loop "${IMAGE}" "${MNT}"
MOUNTED=1

# Nested directory test.
for depth in $(seq 1 40); do
	path="${MNT}/nested"
	for n in $(seq 1 "${depth}"); do
		path="${path}/d${n}"
	done
	run_root mkdir -p "${path}"
	printf 'depth=%s\n' "${depth}" | run_root tee "${path}/marker" >/dev/null
	run_root test -s "${path}/marker"
done

# Many-small-files test.
run_root mkdir -p "${MNT}/small-files"
for i in $(seq 1 2000); do
	printf 'small-file=%s\n' "${i}" | run_root tee "${MNT}/small-files/file-${i}" >/dev/null
done
run_root test -f "${MNT}/small-files/file-2000"

# Medium-file test.
run_root mkdir -p "${MNT}/medium-files"
run_root dd if=/dev/zero of="${MNT}/medium-files/medium.bin" bs=1M count=64 status=none
run_root test -s "${MNT}/medium-files/medium.bin"

# Rename storm.
run_root mkdir -p "${MNT}/rename-storm"
for i in $(seq 1 500); do
	printf 'rename=%s\n' "${i}" | run_root tee "${MNT}/rename-storm/item-${i}" >/dev/null
	run_root mv "${MNT}/rename-storm/item-${i}" "${MNT}/rename-storm/item-${i}.a"
	run_root mv "${MNT}/rename-storm/item-${i}.a" "${MNT}/rename-storm/item-${i}.b"
done

# Delete storm.
run_root mkdir -p "${MNT}/delete-storm"
for i in $(seq 1 1000); do
	printf 'delete=%s\n' "${i}" | run_root tee "${MNT}/delete-storm/item-${i}" >/dev/null
done
for i in $(seq 1 1000); do
	run_root rm "${MNT}/delete-storm/item-${i}"
done
run_root rmdir "${MNT}/delete-storm"

# Remount verification.
run_root sync
run_root umount "${MNT}"
MOUNTED=0
run_root mount -t reiser4 -o loop "${IMAGE}" "${MNT}"
MOUNTED=1
run_root test -f "${MNT}/small-files/file-2000"
run_root test -s "${MNT}/medium-files/medium.bin"
run_root test -f "${MNT}/rename-storm/item-500.b"
run_root test ! -e "${MNT}/delete-storm"
run_root sync
run_root umount "${MNT}"
MOUNTED=0

if command -v fsck.reiser4 >/dev/null 2>&1; then
	run_root fsck.reiser4 -y "${IMAGE}" || fail "fsck.reiser4 failed"
elif command -v reiser4fsck >/dev/null 2>&1; then
	run_root reiser4fsck -y "${IMAGE}" || fail "reiser4fsck failed"
else
	echo "${LOG_PREFIX}: fsck/reiser4progs sanity skipped: no fsck.reiser4 or reiser4fsck found"
fi

run_root rmmod reiser4
MODULE_LOADED=0
scan_dmesg || FAILURES=$((FAILURES + 1))

if (( FAILURES == 0 )); then
	echo "${LOG_PREFIX}: FINAL PASS"
else
	echo "${LOG_PREFIX}: FINAL FAIL failures=${FAILURES}" >&2
	exit 1
fi
