#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
source tests/lib/reiser4_test_lib.sh

if [[ ${EUID} -ne 0 ]]; then
	if command -v sudo >/dev/null 2>&1; then exec sudo -E bash "$0" "$@"; fi
	echo 'SMOKE_PREFLIGHT_FAIL root_or_sudo_required=1'
	exit 1
fi

TEST_NAME=smoke_reiser4_v1
ARTIFACT_DIR=$(r4_make_artifact_dir "${TEST_NAME}")
IMAGE=${REISER4_V1_IMAGE:-/tmp/reiser4-v1.img}
MNT=${REISER4_V1_MNT:-/tmp/reiser4-v1-mnt}
SIZE=${REISER4_V1_SIZE:-128M}
MODULE=${REISER4_MODULE:-./reiser4.ko}
PAYLOAD=${REISER4_V1_PAYLOAD:-v1 payload}
FILE=${MNT}/file
RENAMED=${MNT}/file.renamed
DIRPATH=${MNT}/dir

RESULT=FAIL
FAILED_STAGE=none
MODULE_LOADED_BEFORE=0
MODULE_UNLOADED_AFTER=0
KTXNMGRD_ALIVE_AFTER=0
LOOP_STUCK_AFTER=0
DMESG_DANGER=0
MKDIR_RESULT=SKIP
MKDIR_ERROR=
MKFS_REISER4_VERSION=UNKNOWN
MOUNTED=0
INS_INSERTED=0
HAVE_FILE=0

save_summary_and_exit() {
	local rc=$1
	if r4_module_loaded; then MODULE_UNLOADED_AFTER=0; else MODULE_UNLOADED_AFTER=1; fi
	if r4_ktxnmgrd_alive; then KTXNMGRD_ALIVE_AFTER=1; else KTXNMGRD_ALIVE_AFTER=0; fi
	if r4_any_reiser4_loop_exists; then LOOP_STUCK_AFTER=1; else LOOP_STUCK_AFTER=0; fi
	if r4_dmesg_scan final >"${ARTIFACT_DIR}/dmesg-final-scan.txt" 2>&1; then DMESG_DANGER=0; else DMESG_DANGER=1; fi
	cat >"${ARTIFACT_DIR}/summary.txt" <<SUMMARY
TEST=smoke_reiser4_v1
RESULT=${RESULT}
FAILED_STAGE=${FAILED_STAGE}
GIT_HEAD=$(r4_git_head)
KERNEL=$(uname -a)
MKFS_REISER4_VERSION=${MKFS_REISER4_VERSION}
MODULE_LOADED_BEFORE=${MODULE_LOADED_BEFORE}
MODULE_UNLOADED_AFTER=${MODULE_UNLOADED_AFTER}
KTXNMGRD_ALIVE_AFTER=${KTXNMGRD_ALIVE_AFTER}
LOOP_STUCK_AFTER=${LOOP_STUCK_AFTER}
DMESG_DANGER=${DMESG_DANGER}
MKDIR_RESULT=${MKDIR_RESULT}
MKDIR_ERROR=${MKDIR_ERROR}
SUMMARY
	printf 'SMOKE_ARTIFACTS_AT %s\n' "${ARTIFACT_DIR}"
	printf 'REISER4_SMOKE_END test=%s result=%s failed_stage=%s\n' "${TEST_NAME}" "${RESULT}" "${FAILED_STAGE}"
	exit "${rc}"
}

finish() {
	local rc=$?
	r4_save_dmesg "${ARTIFACT_DIR}" before-cleanup
	if [[ ${MOUNTED} -eq 1 ]]; then
		if out=$(umount "${MNT}" 2>&1); then
			echo 'SMOKE_UNMOUNT_PASS phase=final'
			MOUNTED=0
		else
			printf 'SMOKE_UNMOUNT_FAIL phase=final error="%s"\n' "$(r4_quote_msg "${out}")"
			[[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=final_unmount
			rc=1
		fi
	fi
	# Detach any loop devices left on known Reiser4 smoke images before rmmod.
	while IFS= read -r dev; do
		[[ -n ${dev} ]] || continue
		losetup -d "${dev}" >/dev/null 2>&1 || true
	done < <(losetup -a 2>/dev/null | grep -E '/tmp/reiser4|reiser4.*\.img|\(deleted\)' | cut -d: -f1 || true)
	if r4_module_loaded; then
		if [[ ${MODULE_LOADED_BEFORE} -eq 1 && ${REISER4_ALLOW_PRELOADED:-0} != 1 ]]; then
			echo 'SMOKE_RMMOD_PASS skipped_preloaded=1'
		elif out=$(rmmod reiser4 2>&1); then
			echo 'SMOKE_RMMOD_PASS'
		else
			printf 'SMOKE_RMMOD_FAIL module_ref_stuck=1 error="%s"\n' "$(r4_quote_msg "${out}")"
			[[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=rmmod
			rc=1
		fi
	else
		echo 'SMOKE_RMMOD_PASS already_unloaded=1'
	fi
	r4_save_state "${ARTIFACT_DIR}" after-cleanup
	r4_save_dmesg "${ARTIFACT_DIR}" after-cleanup
	if r4_ktxnmgrd_alive; then echo 'SMOKE_KTXNMGRD_STUCK'; [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=ktxnmgrd; rc=1; fi
	if r4_deleted_reiser4_loop_exists; then echo 'SMOKE_LOOP_STUCK_DELETED_IMAGE'; echo 'SMOKE_LOOP_STUCK deleted_image=1'; [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=loop_deleted; rc=1; fi
	save_summary_and_exit "${rc}"
}
trap finish EXIT

fail_now() {
	local stage=$1
	shift
	FAILED_STAGE=${stage}
	printf '%s\n' "$*"
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
}

printf 'REISER4_SMOKE_BEGIN test=%s artifact_dir=%s\n' "${TEST_NAME}" "${ARTIFACT_DIR}"
r4_save_state "${ARTIFACT_DIR}" before-test
r4_save_dmesg "${ARTIFACT_DIR}" before-test

if r4_module_loaded; then MODULE_LOADED_BEFORE=1; fi
if [[ ${MODULE_LOADED_BEFORE} -eq 1 && ${REISER4_ALLOW_PRELOADED:-0} != 1 ]]; then
	echo 'SMOKE_PREFLIGHT_FAIL module_preloaded=1'
	r4_state preflight-module-preloaded
	FAILED_STAGE=preflight
	r4_save_state "${ARTIFACT_DIR}" after-failure
	exit 1
fi
[[ -e ${MODULE} ]] || fail_now preflight "SMOKE_PREFLIGHT_FAIL missing_module=1 path=\"${MODULE}\""
command -v mkfs.reiser4 >/dev/null 2>&1 || fail_now preflight 'SMOKE_PREFLIGHT_FAIL missing_mkfs_reiser4=1'
MKFS_REISER4_VERSION=$(mkfs.reiser4 -V 2>&1 | head -n 1 || true)
[[ -n ${MKFS_REISER4_VERSION} ]] || MKFS_REISER4_VERSION=UNKNOWN
mkdir -p "${MNT}" || fail_now preflight "SMOKE_PREFLIGHT_FAIL mkdir_mountpoint=1 path=\"${MNT}\""
[[ -n ${IMAGE} && ${IMAGE} == /tmp/reiser4* ]] || fail_now preflight "SMOKE_PREFLIGHT_FAIL unsafe_image_path=1 path=\"${IMAGE}\""
echo 'SMOKE_PREFLIGHT_PASS'

rm -f "${IMAGE}"
truncate -s "${SIZE}" "${IMAGE}" || fail_now mkfs "SMOKE_MKFS_FAIL stage=truncate image=\"${IMAGE}\""
if ! out=$(mkfs.reiser4 -f "${IMAGE}" 2>&1); then
	printf '%s\n' "${out}" >"${ARTIFACT_DIR}/mkfs.log"
	fail_now mkfs "SMOKE_MKFS_FAIL error=\"$(r4_quote_msg "${out}")\""
fi
printf '%s\n' "${out}" >"${ARTIFACT_DIR}/mkfs.log"
echo 'SMOKE_MKFS_PASS'

if [[ ${MODULE_LOADED_BEFORE} -eq 1 && ${REISER4_ALLOW_PRELOADED:-0} == 1 ]]; then
	echo 'SMOKE_INSMOD_PASS preloaded=1'
else
	if ! out=$(insmod "${MODULE}" 2>&1); then
		fail_now insmod "SMOKE_INSMOD_FAIL error=\"$(r4_quote_msg "${out}")\""
	fi
	INS_INSERTED=1
	echo 'SMOKE_INSMOD_PASS'
fi

if ! out=$(mount -t reiser4 -o loop "${IMAGE}" "${MNT}" 2>&1); then
	fail_now mount "SMOKE_MOUNT_FAIL error=\"$(r4_quote_msg "${out}")\""
fi
MOUNTED=1
echo 'SMOKE_MOUNT_PASS'

stat "${MNT}" >"${ARTIFACT_DIR}/root-stat.txt" 2>&1 || fail_now root_stat 'SMOKE_ROOT_STAT_FAIL'
echo 'SMOKE_ROOT_STAT_PASS'

if ! out=$(touch "${FILE}" 2>&1); then
	fail_now file_create "SMOKE_FILE_CREATE_FAIL path=${FILE} error=\"$(r4_quote_msg "${out}")\""
fi
HAVE_FILE=1
echo 'SMOKE_FILE_CREATE_PASS'

if ! out=$(printf '%s\n' "${PAYLOAD}" >"${FILE}" 2>&1); then
	fail_now file_write "SMOKE_FILE_WRITE_FAIL path=${FILE} error=\"$(r4_quote_msg "${out}")\""
fi
if ! out=$(sync 2>&1); then
	fail_now sync "SMOKE_SYNC_FAIL error=\"$(r4_quote_msg "${out}")\""
fi
echo 'SMOKE_FILE_WRITE_PASS'
echo 'SMOKE_SYNC_PASS'
read_back=$(cat "${FILE}" 2>"${ARTIFACT_DIR}/file-read.err") || fail_now file_read "SMOKE_FILE_READ_FAIL path=${FILE} error=\"$(r4_quote_msg "$(cat "${ARTIFACT_DIR}/file-read.err")")\""
[[ ${read_back} == "${PAYLOAD}" ]] || fail_now file_read 'SMOKE_FILE_READ_FAIL mismatch=1'
echo 'SMOKE_FILE_READ_PASS'

if out=$(mkdir "${DIRPATH}" 2>&1); then
	MKDIR_RESULT=PASS
	echo "SMOKE_MKDIR_PASS path=${DIRPATH}"
	if ! out=$(mv "${FILE}" "${RENAMED}" 2>&1); then fail_now rename "SMOKE_RENAME_FAIL error=\"$(r4_quote_msg "${out}")\""; fi
	[[ -f ${RENAMED} ]] || fail_now rename 'SMOKE_RENAME_FAIL verify_missing=1'
	echo 'SMOKE_RENAME_PASS'
	if ! out=$(rm "${RENAMED}" 2>&1); then fail_now delete "SMOKE_DELETE_FAIL error=\"$(r4_quote_msg "${out}")\""; fi
	[[ ! -e ${RENAMED} ]] || fail_now delete 'SMOKE_DELETE_FAIL verify_exists=1'
	HAVE_FILE=0
	echo 'SMOKE_DELETE_PASS'
else
	MKDIR_RESULT=FAIL
	MKDIR_ERROR=${out}
	FAILED_STAGE=mkdir
	printf 'SMOKE_MKDIR_FAIL path=%s error="%s"\n' "${DIRPATH}" "$(r4_quote_msg "${out}")"
	r4_save_state "${ARTIFACT_DIR}" after-failure
	r4_save_dmesg "${ARTIFACT_DIR}" after-mkdir-failure
	grep -E 'BUMRUSH26_MKDIR' "${ARTIFACT_DIR}/dmesg-after-mkdir-failure.txt" >"${ARTIFACT_DIR}/bumrush26-mkdir.txt" 2>/dev/null || true
fi

if ! out=$(sync 2>&1); then [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=sync; printf 'SMOKE_SYNC_FAIL error="%s"\n' "$(r4_quote_msg "${out}")"; exit 1; fi
echo 'SMOKE_SYNC_PASS phase=pre_remount'
if ! out=$(umount "${MNT}" 2>&1); then [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=unmount; printf 'SMOKE_UNMOUNT_FAIL error="%s"\n' "$(r4_quote_msg "${out}")"; exit 1; fi
MOUNTED=0
echo 'SMOKE_UNMOUNT_PASS'
if ! out=$(mount -t reiser4 -o loop "${IMAGE}" "${MNT}" 2>&1); then [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=remount; printf 'SMOKE_REMOUNT_FAIL error="%s"\n' "$(r4_quote_msg "${out}")"; exit 1; fi
MOUNTED=1
echo 'SMOKE_REMOUNT_PASS'
if [[ ${HAVE_FILE} -eq 1 ]]; then
	read_back=$(cat "${FILE}" 2>"${ARTIFACT_DIR}/verify-after-remount.err") || { [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=verify_after_remount; printf 'SMOKE_VERIFY_AFTER_REMOUNT_FAIL error="%s"\n' "$(r4_quote_msg "$(cat "${ARTIFACT_DIR}/verify-after-remount.err")")"; exit 1; }
	[[ ${read_back} == "${PAYLOAD}" ]] || { [[ ${FAILED_STAGE} == none ]] && FAILED_STAGE=verify_after_remount; echo 'SMOKE_VERIFY_AFTER_REMOUNT_FAIL mismatch=1'; exit 1; }
fi
echo 'SMOKE_VERIFY_AFTER_REMOUNT_PASS'

[[ ${FAILED_STAGE} == none ]] && RESULT=PASS || RESULT=FAIL
[[ ${RESULT} == PASS ]] && exit 0 || exit 1
