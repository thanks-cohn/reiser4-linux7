#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE=${REISER4_V1_IMAGE:-/tmp/reiser4-v1.img}
MNT=${REISER4_V1_MNT:-/tmp/reiser4-v1-mnt}
SIZE=${REISER4_V1_SIZE:-128M}
MODULE=${REISER4_MODULE:-./reiser4.ko}
LOG_PREFIX=${LOG_PREFIX:-REISER4_V1}
MODULE_LOADED=0
MOUNTED=0

if [[ ${EUID} -eq 0 ]]; then
	SUDO=()
elif command -v sudo >/dev/null 2>&1; then
	SUDO=(sudo)
else
	echo "${LOG_PREFIX}: root or sudo is required" >&2
	exit 1
fi

run() {
	echo "+ $*" >&2
	"$@"
}

run_root() {
	echo "+ ${SUDO[*]} $*" >&2
	"${SUDO[@]}" "$@"
}

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
	"${SUDO[@]}" dmesg --ctime --color=never 2>/dev/null | tail -200 >&2 || true
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

if [[ ! -e ${MODULE} ]]; then
	build_module || fail "build failed and ${MODULE} does not exist"
fi
[[ -e ${MODULE} ]] || fail "missing module ${MODULE}"
command -v mkfs.reiser4 >/dev/null 2>&1 || fail "mkfs.reiser4 not found in PATH"

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

run_root mkdir "${MNT}/dir"
echo "v1 payload" | run_root tee "${MNT}/dir/file" >/dev/null
read_back=$(run_root cat "${MNT}/dir/file")
[[ ${read_back} == "v1 payload" ]] || fail "readback mismatch"
run_root mv "${MNT}/dir/file" "${MNT}/dir/file.renamed"
run_root test -f "${MNT}/dir/file.renamed"
run_root rm "${MNT}/dir/file.renamed"
run_root test ! -e "${MNT}/dir/file.renamed"
run_root sync
run_root umount "${MNT}"
MOUNTED=0

run_root mount -t reiser4 -o loop "${IMAGE}" "${MNT}"
MOUNTED=1
run_root test -d "${MNT}/dir"
run_root test ! -e "${MNT}/dir/file.renamed"
run_root umount "${MNT}"
MOUNTED=0
run_root rmmod reiser4
MODULE_LOADED=0

echo "${LOG_PREFIX}: PASS"
