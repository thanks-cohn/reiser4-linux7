#!/usr/bin/env bash
# Shared Reiser4-NX V3 smoke-test breadcrumb and artifact helpers.

r4_quote_msg() {
	local msg=${1-}
	msg=${msg//\\/\\\\}
	msg=${msg//"/\\"}
	msg=${msg//$'\n'/; }
	printf '%s' "${msg}"
}

r4_artifact_stamp() { date -u +%Y%m%dT%H%M%SZ; }

r4_artifact_dir() {
	local test_name=${1:?TEST_NAME required}
	local base=${REISER4_ARTIFACT_BASE:-artifacts}
	local stamp dir n
	stamp=$(r4_artifact_stamp)
	dir="${base}/${test_name}-${stamp}"
	n=0
	while [[ -e ${dir} ]]; do
		n=$((n + 1))
		dir="${base}/${test_name}-${stamp}-${n}"
	done
	mkdir -p "${dir}"
	printf '%s\n' "${dir}"
}

# Backward-compatible alias used by older smoke scripts.
r4_make_artifact_dir() { r4_artifact_dir "$@"; }

r4_log() {
	local key=${1:-INFO}; shift || true
	printf '[REISER4_SMOKE] %s' "${key}"
	for value in "$@"; do printf ' %s' "${value}"; done
	printf '\n'
}

r4_pass() {
	local stage=${1:?stage required}; shift || true
	local message=${*:-}
	printf '%s_PASS' "${stage}"
	[[ -n ${message} ]] && printf ' message="%s"' "$(r4_quote_msg "${message}")"
	printf '\n'
	r4_log "${stage}_PASS" "message=\"$(r4_quote_msg "${message}")\""
}

r4_fail() {
	local stage=${1:?stage required}; shift || true
	local message=${*:-}
	printf '%s_FAIL' "${stage}"
	[[ -n ${message} ]] && printf ' error="%s"' "$(r4_quote_msg "${message}")"
	printf '\n'
	r4_log "${stage}_FAIL" "error=\"$(r4_quote_msg "${message}")\""
}

r4_git_head() { git rev-parse HEAD 2>/dev/null || printf 'UNKNOWN'; }
r4_git_status_short() { git status --short 2>/dev/null || true; }
r4_bool() { "$@" >/dev/null 2>&1 && printf 1 || printf 0; }
r4_module_loaded() { lsmod 2>/dev/null | awk '{print $1}' | grep -qx reiser4; }
r4_ktxnmgrd_alive() { ps -ef 2>/dev/null | grep -Eq '[k]txnmgrd'; }
r4_entd_alive() { ps -ef 2>/dev/null | grep -Eq '[e]ntd'; }
r4_any_reiser4_loop_exists() { losetup -a 2>/dev/null | grep -E '/tmp/reiser4|reiser4.*\.img|artifacts/.*/.*\.img|\(deleted\)' >/dev/null; }
r4_deleted_reiser4_loop_exists() { losetup -a 2>/dev/null | grep -E 'reiser4.*\(deleted\)|\(deleted\).*reiser4|artifacts/.*/.*\.img.*\(deleted\)' >/dev/null; }

r4_state() {
	local output_file=${1:?output file required}
	{
		printf 'date=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
		printf 'uname=%s\n' "$(uname -a 2>/dev/null || true)"
		printf 'git_head=%s\n' "$(r4_git_head)"
		printf -- '--- git status --short ---\n'; r4_git_status_short
		printf -- '--- lsmod | grep reiser4 ---\n'; lsmod 2>/dev/null | grep reiser4 || true
		printf -- '--- mount | grep reiser4 ---\n'; mount 2>/dev/null | grep reiser4 || true
		printf -- '--- findmnt | grep reiser4 ---\n'; findmnt 2>/dev/null | grep reiser4 || true
		printf -- '--- losetup -a ---\n'; losetup -a 2>/dev/null || true
		printf -- '--- ps -ef | grep ktxnmgrd/entd ---\n'; ps -ef 2>/dev/null | grep -E '[k]txnmgrd|[e]ntd' || true
		printf -- '--- grep reiser4 /proc/filesystems ---\n'; grep reiser4 /proc/filesystems 2>/dev/null || true
		printf -- '--- df -h ---\n'; df -h 2>/dev/null || true
	} >"${output_file}" 2>&1 || true
}

r4_save_dmesg() {
	local output_file=${1:?output file required}
	local label=${2:-}
	# New V3 API: r4_save_dmesg OUTPUT_FILE.
	# Compatibility API: r4_save_dmesg ARTIFACT_DIR LABEL.
	if [[ -n ${label} || -d ${output_file} ]]; then
		mkdir -p "${output_file}"
		local dir=${output_file}
		local name=${label:-dmesg}
		dmesg --ctime --color=never >"${dir}/dmesg-${name}.txt" 2>&1 || true
		r4_filter_dmesg "${dir}/dmesg-${name}.txt" "${dir}/dmesg-${name}-filtered.txt"
	else
		dmesg --ctime --color=never >"${output_file}" 2>&1 || true
	fi
}

r4_filter_dmesg() {
	local input=${1:?input required} output=${2:?output required}
	grep -E -i 'BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free|general protection fault|unable to handle page fault|hung task|KASAN|UBSAN|lockdep|BUMRUSH26|reiser4|ktxnmgrd|entd' "${input}" >"${output}" 2>/dev/null || true
}

r4_has_dmesg_danger() {
	local input=${1:-}
	# Contract: return nonzero when dangerous dmesg appears, zero when clean.
	if [[ -n ${input} && -f ${input} ]]; then
		if grep -E -i 'BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free|general protection fault|unable to handle page fault|hung task|KASAN|UBSAN|lockdep' "${input}" >/dev/null 2>&1; then return 1; fi
	else
		if dmesg --ctime --color=never 2>/dev/null | grep -E -i 'BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free|general protection fault|unable to handle page fault|hung task|KASAN|UBSAN|lockdep' >/dev/null 2>&1; then return 1; fi
	fi
	return 0
}

r4_cleanup() {
	local artifact_dir=${1:?artifact dir required}
	local target dev loops
	for target in /tmp/reiser4-v1-mnt /mnt/reiser4-smoke /tmp/reiser4-v3-mnt /tmp/reiser4-v3-*mnt /tmp/reiser4-*mnt; do
		[[ -e ${target} ]] && umount "${target}" >/dev/null 2>&1 || true
	done
	while IFS= read -r target; do
		[[ -n ${target} ]] && umount "${target}" >/dev/null 2>&1 || true
	done < <(findmnt -rn -t reiser4 -o TARGET 2>/dev/null || true)
	loops=$(losetup -a 2>/dev/null | awk -F: '/\/tmp\/reiser4|reiser4.*\.img|artifacts\/.*\.img|\(deleted\)/ {print $1}' || true)
	for dev in ${loops}; do losetup -d "${dev}" >/dev/null 2>&1 || true; done
	if [[ ${R4_SKIP_RMMOD:-0} != 1 ]]; then
		if r4_module_loaded; then
			if rmmod reiser4 >/dev/null 2>&1; then
				printf 'SMOKE_RMMOD_PASS\n'
			else
				printf 'SMOKE_RMMOD_FAIL module_ref_stuck=1\n'
			fi
		fi
	fi
	r4_state "${artifact_dir}/state-after-cleanup.txt"
	if r4_ktxnmgrd_alive; then printf 'SMOKE_KTXNMGRD_STUCK\n'; fi
	if r4_entd_alive; then printf 'SMOKE_ENTD_STUCK\n'; fi
	if r4_any_reiser4_loop_exists; then printf 'SMOKE_LOOP_STUCK\n'; fi
	if r4_deleted_reiser4_loop_exists; then printf 'SMOKE_LOOP_STUCK_DELETED_IMAGE\n'; fi
}

r4_write_summary() {
	local artifact_dir=${1:?artifact dir required}; shift || true
	local summary="${artifact_dir}/summary.txt"
	: >"${summary}"
	for kv in "$@"; do printf '%s\n' "${kv}" >>"${summary}"; done
}

r4_require_root() {
	if [[ ${EUID} -ne 0 ]]; then
		printf 'SMOKE_PREFLIGHT_FAIL root_required=1\n'
		return 1
	fi
}

r4_init_test() {
	TEST_NAME=${1:?test name required}
	ARTIFACT_DIR=$(r4_artifact_dir "${TEST_NAME}")
	COMMAND_LOG="${ARTIFACT_DIR}/command-log.txt"
	exec > >(tee -a "${COMMAND_LOG}") 2>&1
	RESULT=FAIL; FAILED_STAGE=none
	MODULE_LOADED_BEFORE=$(r4_bool r4_module_loaded)
	printf '%s_BEGIN\n' "${2:-${TEST_NAME^^}}"
	r4_log TEST_BEGIN "test=${TEST_NAME}" "artifact_dir=\"${ARTIFACT_DIR}\""
	printf 'SMOKE_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
	r4_state "${ARTIFACT_DIR}/state-before.txt"
	r4_save_dmesg "${ARTIFACT_DIR}/dmesg-before.txt"
}

r4_fail_exit() {
	FAILED_STAGE=${1:?failed stage required}; shift || true
	local crumb=${1:?breadcrumb required}; shift || true
	local msg=${*:-}
	if [[ -n ${msg} ]]; then printf '%s error="%s"\n' "${crumb}" "$(r4_quote_msg "${msg}")"; else printf '%s\n' "${crumb}"; fi
	exit 1
}

r4_finish_test() {
	local rc=$?
	r4_state "${ARTIFACT_DIR}/state-after.txt"
	r4_save_dmesg "${ARTIFACT_DIR}/dmesg-after.txt"
	r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-after.txt" "${ARTIFACT_DIR}/dmesg-filtered.txt"
	local module_loaded_after module_unloaded_after_cleanup ktx entd loop dmesg_danger
	module_loaded_after=$(r4_bool r4_module_loaded)
	r4_cleanup "${ARTIFACT_DIR}"
	if [[ ${module_loaded_after} == 0 ]]; then module_unloaded_after_cleanup=1; else module_unloaded_after_cleanup=0; fi
	ktx=$(r4_bool r4_ktxnmgrd_alive); entd=$(r4_bool r4_entd_alive); loop=$(r4_bool r4_any_reiser4_loop_exists)
	if ! r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-after.txt"; then dmesg_danger=1; printf 'SMOKE_DMESG_DANGER\n'; else dmesg_danger=0; fi
	r4_write_summary "${ARTIFACT_DIR}" \
		"TEST=${TEST_NAME}" "RESULT=${RESULT}" "FAILED_STAGE=${FAILED_STAGE}" \
		"GIT_HEAD=$(r4_git_head)" "KERNEL=$(uname -a)" \
		"MODULE_LOADED_BEFORE=${MODULE_LOADED_BEFORE}" "MODULE_LOADED_AFTER=${module_loaded_after}" \
		"MODULE_UNLOADED_AFTER_CLEANUP=${module_unloaded_after_cleanup}" \
		"KTXNMGRD_ALIVE_AFTER=${ktx}" "ENTD_ALIVE_AFTER=${entd}" \
		"LOOP_STUCK_AFTER=${loop}" "DMESG_DANGER=${dmesg_danger}" \
		"ARTIFACT_DIR=${ARTIFACT_DIR}" ${R4_SUMMARY_EXTRA:-}
	printf 'SMOKE_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
	r4_log TEST_END "test=${TEST_NAME}" "result=${RESULT}" "failed_stage=${FAILED_STAGE}"
	exit ${rc}
}

r4_preflight_image_test() {
	r4_require_root || r4_fail_exit preflight SMOKE_PREFLIGHT_FAIL root_required
	[[ -e reiser4.ko ]] || r4_fail_exit preflight SMOKE_PREFLIGHT_FAIL 'missing reiser4.ko; run smoke_build_module first'
	command -v mkfs.reiser4 >/dev/null 2>&1 || r4_fail_exit preflight SMOKE_PREFLIGHT_FAIL 'missing mkfs.reiser4'
	if r4_module_loaded; then R4_SKIP_RMMOD=1; r4_fail_exit preflight SMOKE_PREFLIGHT_FAIL 'module_preloaded=1'; fi
}

r4_make_image() {
	local image=${1:?image} size=${2:-128M}
	rm -f "${image}"
	truncate -s "${size}" "${image}" || return 1
	mkfs.reiser4 -y -f "${image}"
}

r4_mount_new_image() {
	local image=${1:?image} mnt=${2:?mnt} size=${3:-128M}
	mkdir -p "${mnt}" || return 1
	r4_make_image "${image}" "${size}" >"${ARTIFACT_DIR}/mkfs.log" 2>&1 || return 2
	insmod ./reiser4.ko || return 3
	mount -t reiser4 -o loop "${image}" "${mnt}" || return 4
}

# Compatibility wrappers for older V1/V2 smoke scripts retained in this tree.
r4_save_state() {
	local artifact_dir=${1:?artifact dir required} label=${2:-state}
	mkdir -p "${artifact_dir}"
	r4_state "${artifact_dir}/state-${label}.txt"
}

r4_try_cleanup() { r4_cleanup "$@"; }

r4_dmesg_patterns() {
	printf '%s\n' 'BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free|general protection fault|unable to handle page fault|hung task|KASAN|UBSAN|lockdep|BUMRUSH26|reiser4|ktxnmgrd|entd'
}

r4_dmesg_scan() {
	local label=${1:-dmesg}
	local tmp
	tmp=$(mktemp)
	r4_save_dmesg "${tmp}"
	printf -- '--- REISER4_DMESG_SCAN label=%s ---\n' "${label}"
	if ! r4_has_dmesg_danger "${tmp}"; then
		grep -E -i "$(r4_dmesg_patterns)" "${tmp}" || true
		rm -f "${tmp}"
		printf 'SMOKE_DMESG_DANGER label=%s\n' "${label}"
		return 1
	fi
	rm -f "${tmp}"
	printf 'REISER4_DMESG_CLEAN label=%s\n' "${label}"
	return 0
}

# Reiser4-NX V6 production-value smoke-suite helpers.  These are additive so
# older V1/V2/V3 smoke scripts keep their historical APIs and breadcrumbs.
r4_reiser4progs_version() {
	local out=unknown
	if command -v mkfs.reiser4 >/dev/null 2>&1; then
		out=$(mkfs.reiser4 -V 2>&1 | head -n 1 || true)
	elif command -v fsck.reiser4 >/dev/null 2>&1; then
		out=$(fsck.reiser4 -V 2>&1 | head -n 1 || true)
	fi
	[[ -n ${out} ]] || out=unknown
	printf '%s' "${out}"
}

r4_module_refcount() {
	lsmod 2>/dev/null | awk '$1 == "reiser4" {print $3; found=1} END {if (!found) print 0}'
}

r4_require_clean_start() {
	local artifact_dir=${1:?artifact dir required}
	local ok=0
	r4_state "${artifact_dir}/clean-start-state.txt"
	if r4_module_loaded; then printf 'V6_RMMOD_FAIL module_ref_stuck=%s preexisting=1\n' "$(r4_module_refcount)"; ok=1; fi
	if r4_ktxnmgrd_alive; then printf 'V6_KTXNMGRD_STUCK preexisting=1\n'; ok=1; fi
	if r4_entd_alive; then printf 'V6_ENTD_STUCK preexisting=1\n'; ok=1; fi
	if r4_any_reiser4_loop_exists; then printf 'V6_LOOP_STUCK preexisting=1\n'; ok=1; fi
	if r4_deleted_reiser4_loop_exists; then printf 'V6_LOOP_STUCK_DELETED_IMAGE preexisting=1\n'; ok=1; fi
	return "${ok}"
}

r4_hash_manifest() {
	local root=${1:?root required} output_file=${2:?output file required}
	{
		printf '# path\tsize\tsha256\n'
		(cd "${root}" && find . -type f -printf '%P\0' | sort -z | while IFS= read -r -d '' path; do
			local size hash
			size=$(stat -c '%s' "${path}" 2>/dev/null || printf 'MISSING')
			hash=$(sha256sum "${path}" 2>/dev/null | awk '{print $1}' || printf 'MISSING')
			printf '%s\t%s\t%s\n' "${path}" "${size}" "${hash}"
		done)
	} >"${output_file}"
}

r4_verify_hash_manifest() {
	local root=${1:?root required} manifest_file=${2:?manifest required} output_file=${3:?output required}
	local actual expected_paths actual_paths missing=0 extra=0 size_mismatch=0 hash_mismatch=0 checked=0
	actual=$(mktemp)
	expected_paths=$(mktemp)
	actual_paths=$(mktemp)
	r4_hash_manifest "${root}" "${actual}"
	awk -F '\t' 'substr($0,1,1) != "#" {print $1}' "${manifest_file}" | sort >"${expected_paths}"
	awk -F '\t' 'substr($0,1,1) != "#" {print $1}' "${actual}" | sort >"${actual_paths}"
	{
		printf 'VERIFY_ROOT=%s\n' "${root}"
		printf 'MANIFEST=%s\n' "${manifest_file}"
		printf -- '--- missing files ---\n'
		comm -23 "${expected_paths}" "${actual_paths}" || true
		printf -- '--- extra files ---\n'
		comm -13 "${expected_paths}" "${actual_paths}" || true
		printf -- '--- mismatches ---\n'
		while IFS=$'\t' read -r path size hash; do
			[[ -n ${path} && ${path:0:1} != '#' ]] || continue
			checked=$((checked + 1))
			if [[ ! -f ${root}/${path} ]]; then
				missing=$((missing + 1)); printf 'MISSING\t%s\n' "${path}"; continue
			fi
			local got_size got_hash
			got_size=$(stat -c '%s' "${root}/${path}" 2>/dev/null || printf 'MISSING')
			if [[ ${got_size} != "${size}" ]]; then size_mismatch=$((size_mismatch + 1)); printf 'SIZE_MISMATCH\t%s\texpected=%s\tactual=%s\n' "${path}" "${size}" "${got_size}"; fi
			got_hash=$(sha256sum "${root}/${path}" 2>/dev/null | awk '{print $1}' || printf 'MISSING')
			if [[ ${got_hash} != "${hash}" ]]; then hash_mismatch=$((hash_mismatch + 1)); printf 'HASH_MISMATCH\t%s\texpected=%s\tactual=%s\n' "${path}" "${hash}" "${got_hash}"; fi
		done <"${manifest_file}"
		extra=$(comm -13 "${expected_paths}" "${actual_paths}" | wc -l | tr -d ' ')
		missing=$((missing + $(comm -23 "${expected_paths}" "${actual_paths}" | wc -l | tr -d ' ')))
		printf 'CHECKED=%s\nMISSING=%s\nEXTRA=%s\nSIZE_MISMATCH=%s\nHASH_MISMATCH=%s\n' "${checked}" "${missing}" "${extra}" "${size_mismatch}" "${hash_mismatch}"
	} >"${output_file}"
	rm -f "${actual}" "${expected_paths}" "${actual_paths}"
	[[ ${missing} -eq 0 && ${extra} -eq 0 && ${size_mismatch} -eq 0 && ${hash_mismatch} -eq 0 ]]
}

r4_fsck_image() {
	local image=${1:?image required} output_file=${2:?output required}
	local rc=0
	{
		printf 'FSCK_IMAGE=%s\n' "${image}"
		if command -v fsck.reiser4 >/dev/null 2>&1; then
			printf 'FSCK_VERSION=%s\n' "$(fsck.reiser4 -V 2>&1 | head -n 1 || printf unknown)"
		else
			printf 'FSCK_VERSION=unknown\n'
		fi
		if ! command -v fsck.reiser4 >/dev/null 2>&1; then
			printf 'FSCK_MISSING=1\n'
			rc=127
		else
			timeout "${R4_FSCK_TIMEOUT:-300}" fsck.reiser4 -y "${image}"
			rc=$?
		fi
		printf 'FSCK_EXIT=%s\n' "${rc}"
	} >"${output_file}" 2>&1
	return "${rc}"
}

r4_v6_init() {
	TEST_NAME=${1:?test name required}
	V6_BEGIN_CRUMB=${2:?begin breadcrumb required}
	ARTIFACT_DIR=$(r4_artifact_dir "${TEST_NAME}")
	COMMAND_LOG="${ARTIFACT_DIR}/command-log.txt"
	exec > >(tee -a "${COMMAND_LOG}") 2>&1
	RESULT=FAIL; FAILED_STAGE=none; SILENT_CORRUPTION=0
	MODULE_LOADED_BEFORE=$(r4_bool r4_module_loaded)
	printf '%s\n' "${V6_BEGIN_CRUMB}"
	printf 'V6_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
	r4_log TEST_BEGIN "test=${TEST_NAME}" "artifact_dir=\"${ARTIFACT_DIR}\""
	r4_state "${ARTIFACT_DIR}/state-before.txt"
	r4_save_dmesg "${ARTIFACT_DIR}/dmesg-before.txt"
}

r4_v6_fail_exit() {
	FAILED_STAGE=${1:?stage required}; shift
	local crumb=${1:?breadcrumb required}; shift
	local msg=${*:-}
	[[ -n ${msg} ]] && printf '%s error="%s"\n' "${crumb}" "$(r4_quote_msg "${msg}")" || printf '%s\n' "${crumb}"
	exit 1
}

r4_v6_finish() {
	local rc=$?
	r4_state "${ARTIFACT_DIR}/state-after.txt"
	r4_save_dmesg "${ARTIFACT_DIR}/dmesg-after.txt"
	r4_filter_dmesg "${ARTIFACT_DIR}/dmesg-after.txt" "${ARTIFACT_DIR}/dmesg-filtered.txt"
	local module_loaded_after module_unloaded_after_cleanup ktx entd loop dmesg_danger
	module_loaded_after=$(r4_bool r4_module_loaded)
	r4_cleanup "${ARTIFACT_DIR}"
	module_unloaded_after_cleanup=$([[ $(r4_bool r4_module_loaded) == 0 ]] && printf 1 || printf 0)
	ktx=$(r4_bool r4_ktxnmgrd_alive); entd=$(r4_bool r4_entd_alive); loop=$(r4_bool r4_any_reiser4_loop_exists)
	if ! r4_has_dmesg_danger "${ARTIFACT_DIR}/dmesg-after.txt"; then dmesg_danger=1; printf 'V6_DMESG_DANGER\n'; else dmesg_danger=0; fi
	if r4_module_loaded; then printf 'V6_RMMOD_FAIL module_ref_stuck=%s\n' "$(r4_module_refcount)"; fi
	if r4_ktxnmgrd_alive; then printf 'V6_KTXNMGRD_STUCK\n'; fi
	if r4_entd_alive; then printf 'V6_ENTD_STUCK\n'; fi
	if r4_any_reiser4_loop_exists; then printf 'V6_LOOP_STUCK\n'; fi
	if r4_deleted_reiser4_loop_exists; then printf 'V6_LOOP_STUCK_DELETED_IMAGE\n'; fi
	if [[ ${SILENT_CORRUPTION:-0} == 1 ]]; then printf 'V6_SILENT_CORRUPTION_DETECTED\n'; fi
	r4_write_summary "${ARTIFACT_DIR}" \
		"TEST=${TEST_NAME}" "RESULT=${RESULT}" "FAILED_STAGE=${FAILED_STAGE}" \
		"GIT_HEAD=$(r4_git_head)" "KERNEL=$(uname -a)" \
		"REISER4PROGS_VERSION=$(r4_reiser4progs_version)" \
		"MODULE_LOADED_BEFORE=${MODULE_LOADED_BEFORE}" "MODULE_LOADED_AFTER=${module_loaded_after}" \
		"MODULE_UNLOADED_AFTER_CLEANUP=${module_unloaded_after_cleanup}" \
		"KTXNMGRD_ALIVE_AFTER=${ktx}" "ENTD_ALIVE_AFTER=${entd}" \
		"LOOP_STUCK_AFTER=${loop}" "DMESG_DANGER=${dmesg_danger}" \
		"SILENT_CORRUPTION=${SILENT_CORRUPTION:-0}" "ARTIFACT_DIR=${ARTIFACT_DIR}" ${R4_SUMMARY_EXTRA:-}
	printf 'V6_ARTIFACTS_AT path="%s"\n' "${ARTIFACT_DIR}"
	r4_log TEST_END "test=${TEST_NAME}" "result=${RESULT}" "failed_stage=${FAILED_STAGE}"
	exit "${rc}"
}

r4_v6_require_root_and_tools() {
	if [[ ${EUID} -ne 0 ]]; then r4_v6_fail_exit preflight "${1:-V6_PREFLIGHT_FAIL}" root_required=1; fi
	[[ -e ./reiser4.ko ]] || r4_v6_fail_exit preflight "${1:-V6_PREFLIGHT_FAIL}" missing_reiser4_ko=1
	command -v mkfs.reiser4 >/dev/null 2>&1 || r4_v6_fail_exit preflight "${1:-V6_PREFLIGHT_FAIL}" missing_mkfs_reiser4=1
}

r4_v6_mount_image() {
	local image=${1:?image} mnt=${2:?mnt} size=${3:-256M}
	rm -f "${image}"; mkdir -p "${mnt}"
	truncate -s "${size}" "${image}" || return 1
	mkfs.reiser4 -y -f "${image}" >"${ARTIFACT_DIR}/mkfs-$(basename "${image}").log" 2>&1 || return 2
	if ! r4_module_loaded; then insmod ./reiser4.ko || return 3; fi
	mount -t reiser4 -o loop "${image}" "${mnt}" || return 4
}

r4_v6_unmount_image() {
	local image=${1:?image} mnt=${2:?mnt}
	sync || true
	umount "${mnt}" || return 1
	while IFS= read -r dev; do [[ -n ${dev} ]] && losetup -d "${dev}" >/dev/null 2>&1 || true; done < <(losetup -j "${image}" 2>/dev/null | cut -d: -f1 || true)
}
