#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT_DIR="${OUT_DIR:-${ROOT_DIR}/artifacts/large-filename-probe-${TIMESTAMP}}"
IMG="${IMG:-${OUT_DIR}/reiser4-large-filename.img}"
MNT="${MNT:-${OUT_DIR}/mnt}"
IMG_SIZE="${IMG_SIZE:-512M}"
RESULTS="${OUT_DIR}/results.tsv"
SUMMARY="${OUT_DIR}/summary.txt"
ATTEMPTS=(1 64 128 255 256 512 1024 2048 3976 4032 4096)
DANGEROUS_DMESG_PATTERN='BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free|general protection fault|unable to handle page fault'
SUDO=()
MOUNTED=0
FAILED=0
FAIL_REASON=""
SUCCESSFUL_LENGTHS=()
MAX_SUCCESS=0
DMESG_STATUS="not-run"

if [[ "$(id -u)" -ne 0 ]]; then
	SUDO=(sudo)
fi

mkdir -p "${OUT_DIR}" "${MNT}"
LOG="${OUT_DIR}/large-filename-probe.log"
exec > >(tee -a "${LOG}") 2>&1
export LAST_TEST_LOG="${LOG}"

log() {
	printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

write_summary() {
	{
		echo "Large filename probe summary"
		echo "artifact_dir=${OUT_DIR}"
		echo "image=${IMG}"
		echo "attempted_lengths=${ATTEMPTS[*]}"
		echo "successful_lengths=${SUCCESSFUL_LENGTHS[*]:-none}"
		echo "max_observed_successful_component_length=${MAX_SUCCESS}"
		echo "dmesg_status=${DMESG_STATUS}"
		echo "results=${RESULTS}"
		if [[ "${FAILED}" -ne 0 ]]; then
			echo "overall=FAIL"
			echo "failure_reason=${FAIL_REASON}"
		else
			echo "overall=PASS"
		fi
	} >"${SUMMARY}"
}

mark_failure() {
	local reason=$1
	FAILED=1
	FAIL_REASON="${reason}"
	log "FAILURE: ${reason}"
	write_summary
	if [[ -x "${ROOT_DIR}/tools/reiser4_failure_bundle.sh" ]]; then
		"${ROOT_DIR}/tools/reiser4_failure_bundle.sh" "${OUT_DIR}/failure-bundle" || true
	fi
}

cleanup() {
	set +e
	if [[ "${MOUNTED}" -eq 1 ]] || findmnt -rn "${MNT}" >/dev/null 2>&1; then
		"${SUDO[@]}" umount "${MNT}" >/dev/null 2>&1 || true
	fi
}
trap cleanup EXIT

run_or_fail() {
	local description=$1
	shift
	log "+ $*"
	if ! "$@"; then
		mark_failure "${description} failed"
		exit 1
	fi
}

capture_environment() {
	if [[ -x "${ROOT_DIR}/tools/reiser4_env_report.sh" ]]; then
		"${ROOT_DIR}/tools/reiser4_env_report.sh" >"${OUT_DIR}/env-report.log" 2>&1 || true
	else
		{
			uname -a
			command -v mkfs.reiser4 || true
			git -C "${ROOT_DIR}" rev-parse HEAD || true
			git -C "${ROOT_DIR}" status --short || true
		} >"${OUT_DIR}/env-report.log" 2>&1 || true
	fi
}

load_reiser4_if_needed() {
	if grep -qw reiser4 /proc/filesystems; then
		log "reiser4 already listed in /proc/filesystems"
		return 0
	fi

	if lsmod 2>/dev/null | awk '{print $1}' | grep -qx reiser4; then
		log "reiser4 module already loaded"
		return 0
	fi

	if "${SUDO[@]}" modprobe reiser4; then
		log "loaded reiser4 with modprobe"
		return 0
	fi

	local module_path="${ROOT_DIR}/fs/reiser4/reiser4.ko"
	if [[ -f "${module_path}" ]] && "${SUDO[@]}" insmod "${module_path}"; then
		log "loaded ${module_path} with insmod"
		return 0
	fi

	return 1
}

attempt_name() {
	local len=$1
	local phase=$2
	local phase_dir="${OUT_DIR}/${phase}"
	mkdir -p "${phase_dir}"
	local stderr_file="${phase_dir}/len-${len}.stderr"
	local stdout_file="${phase_dir}/len-${len}.stdout"

	set +e
	python3 - "${MNT}" "${len}" "${phase}" >"${stdout_file}" 2>"${stderr_file}" <<'PY'
import errno
import os
import sys

mnt = sys.argv[1]
length = int(sys.argv[2])
phase = sys.argv[3]
name = "n" * length
path = os.path.join(mnt, name)
content = f"reiser4 large filename probe length={length}\n".encode("utf-8")

try:
    if phase == "create":
        with open(path, "wb") as handle:
            handle.write(content)
        with open(path, "rb") as handle:
            read_back = handle.read()
        if read_back != content:
            print("verification mismatch after create", file=sys.stderr)
            sys.exit(20)
        print(f"OK create len={length}")
    elif phase == "verify":
        with open(path, "rb") as handle:
            read_back = handle.read()
        if read_back != content:
            print("verification mismatch after remount", file=sys.stderr)
            sys.exit(21)
        print(f"OK verify len={length}")
    else:
        print(f"unknown phase: {phase}", file=sys.stderr)
        sys.exit(22)
except OSError as exc:
    err_name = errno.errorcode.get(exc.errno, "UNKNOWN")
    print(f"OSError errno={exc.errno} name={err_name} message={exc.strerror}", file=sys.stderr)
    sys.exit(10)
PY
	local rc=$?
	set -e

	local message
	message="$(tr '\n' ' ' <"${stderr_file}" | sed 's/[[:space:]]\+$//')"
	if [[ -z "${message}" ]]; then
		message="$(tr '\n' ' ' <"${stdout_file}" | sed 's/[[:space:]]\+$//')"
	fi

	if [[ "${rc}" -eq 0 ]]; then
		printf '%s\t%s\tsuccess\t0\t%s\n' "${phase}" "${len}" "${message}" >>"${RESULTS}"
		return 0
	else
		printf '%s\t%s\tfailure\t%s\t%s\n' "${phase}" "${len}" "${rc}" "${message}" >>"${RESULTS}"
		return "${rc}"
	fi
}

scan_dmesg() {
	local target=$1
	if dmesg -T >"${target}" 2>&1; then
		if grep -Ei "${DANGEROUS_DMESG_PATTERN}" "${target}" >"${OUT_DIR}/dangerous-dmesg-matches.txt"; then
			return 1
		fi
	else
		echo "dmesg unavailable or permission denied" >"${target}"
	fi
	return 0
}

log "large filename probe artifact directory: ${OUT_DIR}"
capture_environment
printf 'phase\tlength\tresult\trc\tmessage\n' >"${RESULTS}"

dmesg -T >"${OUT_DIR}/dmesg-before.log" 2>&1 || true

if ! command -v mkfs.reiser4 >/dev/null 2>&1; then
	mark_failure "mkfs.reiser4 not found"
	exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
	mark_failure "python3 not found"
	exit 1
fi

run_or_fail "image creation" truncate -s "${IMG_SIZE}" "${IMG}"
log "+ mkfs.reiser4 -y -f ${IMG}"
if ! mkfs.reiser4 -y -f "${IMG}" >"${OUT_DIR}/mkfs.reiser4.log" 2>&1; then
	mark_failure "mkfs.reiser4 failed"
	exit 1
fi

if ! load_reiser4_if_needed; then
	mark_failure "unable to load or find reiser4 filesystem support"
	exit 1
fi

log "+ mount -o loop -t reiser4 ${IMG} ${MNT}"
if ! "${SUDO[@]}" mount -o loop -t reiser4 "${IMG}" "${MNT}"; then
	mark_failure "initial mount failed"
	exit 1
fi
MOUNTED=1

for len in "${ATTEMPTS[@]}"; do
	log "attempt create length=${len}"
	if attempt_name "${len}" create; then
		SUCCESSFUL_LENGTHS+=("${len}")
		MAX_SUCCESS="${len}"
		if ! sync; then
			mark_failure "sync failed after length ${len}"
			exit 1
		fi
	else
		log "create length=${len} failed safely or was rejected; continuing"
	fi
done

log "+ sync"
sync
log "+ umount ${MNT}"
if ! "${SUDO[@]}" umount "${MNT}"; then
	mark_failure "unmount after create phase failed"
	exit 1
fi
MOUNTED=0

log "+ remount ${IMG} ${MNT}"
if ! "${SUDO[@]}" mount -o loop -t reiser4 "${IMG}" "${MNT}"; then
	mark_failure "remount failed"
	exit 1
fi
MOUNTED=1

for len in "${SUCCESSFUL_LENGTHS[@]}"; do
	log "verify after remount length=${len}"
	if ! attempt_name "${len}" verify; then
		mark_failure "successful length ${len} did not verify after remount"
		exit 1
	fi
done

log "+ umount ${MNT}"
if ! "${SUDO[@]}" umount "${MNT}"; then
	mark_failure "final unmount failed"
	exit 1
fi
MOUNTED=0

DMESG_STATUS="clean"
if ! scan_dmesg "${OUT_DIR}/dmesg-after.log"; then
	DMESG_STATUS="dangerous-pattern-detected"
	FAILED=1
	FAIL_REASON="dangerous dmesg pattern detected"
	if [[ -x "${ROOT_DIR}/tools/reiser4_failure_bundle.sh" ]]; then
		"${ROOT_DIR}/tools/reiser4_failure_bundle.sh" "${OUT_DIR}/failure-bundle" || true
	fi
fi

write_summary
cat "${SUMMARY}"

if [[ "${FAILED}" -ne 0 ]]; then
	exit 1
fi
