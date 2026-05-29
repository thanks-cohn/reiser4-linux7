#!/usr/bin/env bash
set -u -o pipefail
ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "${ROOT_DIR}"
# shellcheck source=tests/lib/reiser4_test_lib.sh
source tests/lib/reiser4_test_lib.sh

r4_init_test smoke_v3_repeat_from_clean_boot SMOKE_V3_REPEAT_FROM_CLEAN_BOOT
trap r4_finish_test EXIT
boot_time=$(awk '/^btime /{print $2}' /proc/stat 2>/dev/null || true)
uptime_s=$(cut -d. -f1 /proc/uptime 2>/dev/null || echo unknown)
r4_log BOOT "btime=${boot_time:-unknown}" "uptime_seconds=${uptime_s}"
r4_log GIT "head=$(r4_git_head)" "kernel=\"$(uname -a)\""
if [[ ! -f .reiser4-v3-reboot-marker ]]; then printf 'SMOKE_REBOOT_MARKER_WARNING missing_marker=1\n'; fi
# Avoid recursive suite call. Repeat the short V3 stress as the post-boot validation workload.
if tests/smoke_v3_short_stress.sh >"${ARTIFACT_DIR}/repeat-short-stress.log" 2>&1; then
	printf 'SMOKE_REPEAT_SHORT_STRESS_PASS\n'
else
	FAILED_STAGE=repeat_short_stress
	printf 'SMOKE_V3_REPEAT_FROM_CLEAN_BOOT_FAIL stage=repeat_short_stress log="%s"\n' "${ARTIFACT_DIR}/repeat-short-stress.log"
	exit 1
fi
find artifacts -maxdepth 2 -name summary.txt -print | sort >"${ARTIFACT_DIR}/all-summaries.txt" 2>/dev/null || true
r4_cleanup "${ARTIFACT_DIR}"
if r4_module_loaded || r4_ktxnmgrd_alive || r4_entd_alive || r4_any_reiser4_loop_exists; then FAILED_STAGE=final_clean_state; printf 'SMOKE_V3_REPEAT_FROM_CLEAN_BOOT_FAIL stage=final_clean_state\n'; exit 1; fi
RESULT=PASS
printf 'SMOKE_V3_REPEAT_FROM_CLEAN_BOOT_PASS\n'
