#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_repeated_mount_unmount_10 SMOKE_REPEATED_MOUNT_UNMOUNT_10
trap r4_finish_test EXIT
r4_preflight_image_test
IMAGE=${ARTIFACT_DIR}/test.img; MNT=/tmp/reiser4-v3-${TEST_NAME}-mnt; SIZE=${REISER4_SMOKE_SIZE:-128M}
mkdir -p "${MNT}" || r4_fail_exit preflight SMOKE_REPEATED_MOUNT_UNMOUNT_10_FAIL mkdir_mountpoint_failed
r4_make_image "${IMAGE}" "${SIZE}" >"${ARTIFACT_DIR}/mkfs.log" 2>&1 || r4_fail_exit mkfs SMOKE_REPEATED_MOUNT_UNMOUNT_10_FAIL mkfs_failed
insmod ./reiser4.ko || r4_fail_exit insmod SMOKE_REPEATED_MOUNT_UNMOUNT_10_FAIL insmod_failed
for cycle in $(seq 1 10); do
	if mount -t reiser4 -o loop "${IMAGE}" "${MNT}" >"${ARTIFACT_DIR}/mount-${cycle}.log" 2>&1 && umount "${MNT}" >"${ARTIFACT_DIR}/umount-${cycle}.log" 2>&1; then
		ref=$(lsmod | awk '$1=="reiser4"{print $3}' || true); r4_log MOUNT_CYCLE "cycle=${cycle}" "module_refcount=${ref:-unknown}" "loop_state=\"$(losetup -a | tr '\n' ';' | r4_quote_msg)\""; printf 'SMOKE_MOUNT_CYCLE_PASS cycle=%s\n' "${cycle}"
	else
		FAILED_STAGE=cycle_${cycle}; printf 'SMOKE_MOUNT_CYCLE_FAIL cycle=%s\n' "${cycle}"; exit 1
	fi
done
RESULT=PASS
printf 'SMOKE_REPEATED_MOUNT_UNMOUNT_10_PASS\n'
