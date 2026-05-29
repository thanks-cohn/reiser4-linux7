#!/usr/bin/env bash
# Shared Reiser4-NX smoke-test breadcrumb and artifact helpers.

r4_quote_msg() {
	local msg=${1-}
	msg=${msg//\\/\\\\}
	msg=${msg//"/\\"}
	printf '%s' "${msg}"
}

r4_log() {
	local step=${1:-unknown}
	local status=${2:-INFO}
	local msg=${3:-}
	printf '[REISER4_TEST] step=%s status=%s msg="%s"\n' "${step}" "${status}" "$(r4_quote_msg "${msg}")"
}

r4_pass() { r4_log "${1:-unknown}" PASS "${2:-}"; }
r4_fail() { r4_log "${1:-unknown}" FAIL "${2:-}"; }
r4_skip() { r4_log "${1:-unknown}" SKIP "${2:-}"; }

r4_git_head() { git rev-parse HEAD 2>/dev/null || printf 'UNKNOWN'; }
r4_git_status_short() { git status --short 2>/dev/null || true; }

r4_artifact_stamp() { date -u +%Y%m%dT%H%M%SZ; }

r4_make_artifact_dir() {
	local test_name=${1:?test name required}
	local base=${REISER4_ARTIFACT_BASE:-artifacts}
	local dir="${base}/${test_name}-$(r4_artifact_stamp)"
	mkdir -p "${dir}"
	printf '%s\n' "${dir}"
}

r4_dmesg_patterns() {
	cat <<'EOF_PATTERNS'
BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free|general protection fault|unable to handle page fault|hung task|KASAN|UBSAN|lockdep|BUMRUSH26_MKDIR
EOF_PATTERNS
}

r4_dmesg_scan() {
	local label=${1:-dmesg}
	local pattern
	pattern=$(r4_dmesg_patterns)
	printf -- '--- REISER4_DMESG_SCAN label=%s ---\n' "${label}"
	if dmesg --ctime --color=never 2>/dev/null | grep -E -i "${pattern}"; then
		printf 'SMOKE_DMESG_DANGER label=%s\n' "${label}"
		return 1
	fi
	printf 'REISER4_DMESG_CLEAN label=%s\n' "${label}"
	return 0
}

r4_state() {
	local label=${1:-state}
	local artifact_dir=${ARTIFACT_DIR:-${R4_ARTIFACT_DIR:-}}
	printf -- '--- REISER4_STATE_BEGIN label=%s ---\n' "${label}"
	printf 'timestamp=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	printf 'uname=%s\n' "$(uname -a 2>/dev/null || true)"
	printf 'git_head=%s\n' "$(r4_git_head)"
	printf -- '--- git_status_short ---\n'
	r4_git_status_short
	printf -- '--- lsmod_reiser4 ---\n'
	lsmod 2>/dev/null | grep -E '^reiser4\b' || true
	printf -- '--- mount_reiser4 ---\n'
	mount 2>/dev/null | grep -E 'reiser4|/tmp/reiser4' || true
	printf -- '--- findmnt_reiser4 ---\n'
	findmnt 2>/dev/null | grep -E 'reiser4|/tmp/reiser4' || true
	printf -- '--- losetup_all ---\n'
	losetup -a 2>/dev/null || true
	printf -- '--- ps_ktxnmgrd_entd ---\n'
	ps -ef 2>/dev/null | grep -E '[k]txnmgrd|[e]ntd' || true
	printf -- '--- proc_filesystems_reiser4 ---\n'
	grep -E 'reiser4' /proc/filesystems 2>/dev/null || true
	if [[ -n ${artifact_dir} && -d ${artifact_dir} ]]; then
		printf -- '--- artifact_du artifact_dir=%s ---\n' "${artifact_dir}"
		du -sh "${artifact_dir}" 2>/dev/null || true
	fi
	printf -- '--- REISER4_STATE_END label=%s ---\n' "${label}"
}

r4_save_state() {
	local artifact_dir=${1:?artifact dir required}
	local label=${2:-state}
	mkdir -p "${artifact_dir}"
	ARTIFACT_DIR="${artifact_dir}" r4_state "${label}" >"${artifact_dir}/state-${label}.txt" 2>&1 || true
}

r4_save_dmesg() {
	local artifact_dir=${1:?artifact dir required}
	local label=${2:-dmesg}
	local pattern
	pattern=$(r4_dmesg_patterns)
	mkdir -p "${artifact_dir}"
	dmesg --ctime --color=never >"${artifact_dir}/dmesg-${label}.txt" 2>&1 || true
	grep -E -i "${pattern}" "${artifact_dir}/dmesg-${label}.txt" >"${artifact_dir}/dmesg-${label}-filtered.txt" 2>/dev/null || true
}

r4_module_loaded() { lsmod 2>/dev/null | awk '{print $1}' | grep -qx reiser4; }
r4_ktxnmgrd_alive() { ps -ef 2>/dev/null | grep -Eq '[k]txnmgrd|[e]ntd'; }
r4_deleted_reiser4_loop_exists() { losetup -a 2>/dev/null | grep -E 'reiser4.*\(deleted\)|\(deleted\).*reiser4' >/dev/null; }
r4_any_reiser4_loop_exists() { losetup -a 2>/dev/null | grep -E '/tmp/reiser4|reiser4.*\.img|\(deleted\)' >/dev/null; }

r4_try_cleanup() {
	local artifact_dir=${1:?artifact dir required}
	local target loops dev
	printf -- '--- REISER4_TRY_CLEANUP_BEGIN artifact_dir=%s ---\n' "${artifact_dir}"

	while IFS= read -r target; do
		[[ -n ${target} ]] || continue
		case "${target}" in
			/tmp/reiser4*|/mnt/reiser4*) umount "${target}" >/dev/null 2>&1 || true ;;
		esac
	done < <(findmnt -rn -t reiser4 -o TARGET 2>/dev/null || true)

	for target in /tmp/reiser4-v1-mnt /tmp/reiser4-smoke-mnt /tmp/reiser4-mkfs-mount-mnt /tmp/reiser4-rw-mnt /tmp/reiser4-mkdir-mnt /tmp/reiser4-teardown-mnt; do
		umount "${target}" >/dev/null 2>&1 || true
	done

	loops=$(losetup -a 2>/dev/null | grep -E '/tmp/reiser4|reiser4.*\.img|\(deleted\)' | cut -d: -f1 || true)
	for dev in ${loops}; do
		losetup -d "${dev}" >/dev/null 2>&1 || true
	done

	if [[ ${R4_SKIP_RMMOD:-0} != 1 ]]; then
		rmmod reiser4 >/dev/null 2>&1 || true
	fi

	r4_save_state "${artifact_dir}" after-cleanup
	r4_save_dmesg "${artifact_dir}" after-cleanup
	if r4_module_loaded; then
		printf 'REISER4_TEARDOWN_FAIL module_still_loaded=1\n'
	fi
	if r4_ktxnmgrd_alive; then
		printf 'REISER4_TEARDOWN_FAIL ktxnmgrd_alive=1\n'
	fi
	if r4_deleted_reiser4_loop_exists; then
		printf 'REISER4_TEARDOWN_FAIL deleted_loop_image=1\n'
	fi
	printf -- '--- REISER4_TRY_CLEANUP_END artifact_dir=%s ---\n' "${artifact_dir}"
}
