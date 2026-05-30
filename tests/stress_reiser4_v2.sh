#!/usr/bin/env bash
set -Eeuo pipefail

ITERATIONS=${1:-${REISER4_V2_ITERATIONS:-100}}
IMAGE=${REISER4_V2_IMAGE:-/tmp/reiser4-v2.img}
MNT=${REISER4_V2_MNT:-/tmp/reiser4-v2-mnt}
SIZE=${REISER4_V2_SIZE:-512M}
MODULE=${REISER4_MODULE:-./reiser4.ko}
REMOUNT_EVERY=${REISER4_V2_REMOUNT_EVERY:-$(( ITERATIONS >= 50 ? ITERATIONS / 50 : 1 ))}
SYNC_EVERY=${REISER4_V2_SYNC_EVERY:-10}
LOG_PREFIX=${LOG_PREFIX:-REISER4_V2}
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
	"${SUDO[@]}" dmesg --ctime --color=never 2>/dev/null | tail -300 >&2 || true
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
(( ITERATIONS > 0 )) || fail "iteration count must be positive"
(( REMOUNT_EVERY > 0 )) || REMOUNT_EVERY=1

run_root umount "${MNT}" 2>/dev/null || true
run_root rmmod reiser4 2>/dev/null || true
run rm -f "${IMAGE}"
run mkdir -p "${MNT}"
run truncate -s "${SIZE}" "${IMAGE}"
run_root mkfs.reiser4 -y -f "${IMAGE}"
run_root insmod "${MODULE}"
MODULE_LOADED=1
run_root mount -t reiser4 -o loop "${IMAGE}" "${MNT}"
MOUNTED=1

for i in $(seq 1 "${ITERATIONS}"); do
	dir="${MNT}/loop-${i}/nested/a/b/c"
	run_root mkdir -p "${dir}"
	for j in $(seq 1 8); do
		file="${dir}/file-${j}.txt"
		printf 'iteration=%s file=%s\n' "${i}" "${j}" | run_root tee "${file}" >/dev/null
		run_root test -s "${file}"
		run_root mv "${file}" "${file}.renamed"
		run_root test -f "${file}.renamed"
	done
	for j in $(seq 1 4); do
		run_root rm "${dir}/file-${j}.txt.renamed"
	done
	if (( i % SYNC_EVERY == 0 )); then
		run_root sync
	fi
	if (( i % REMOUNT_EVERY == 0 )); then
		run_root sync
		run_root umount "${MNT}"
		MOUNTED=0
		run_root mount -t reiser4 -o loop "${IMAGE}" "${MNT}"
		MOUNTED=1
		run_root test -d "${MNT}/loop-${i}/nested/a/b/c"
	fi
done

run_root sync
run_root umount "${MNT}"
MOUNTED=0
run_root rmmod reiser4
MODULE_LOADED=0

echo "${LOG_PREFIX}: PASS iterations=${ITERATIONS} remount_every=${REMOUNT_EVERY}"
