#!/usr/bin/env bash
set -Eeuo pipefail

run_section() {
	local title=$1
	shift
	printf '\n## %s\n' "${title}"
	printf '+ %s\n' "$*"
	"$@" 2>&1 || printf 'command failed: %s\n' "$*"
}

run_pipe_section() {
	local title=$1
	local command=$2
	printf '\n## %s\n' "${title}"
	printf '+ %s\n' "${command}"
	bash -o pipefail -c "${command}" 2>&1 || printf 'command failed: %s\n' "${command}"
}

run_section "uname -a" uname -a
run_section "gcc --version" gcc --version
run_section "make --version" make --version
run_pipe_section "mkfs.reiser4 version" 'mkfs.reiser4 -V 2>&1 || mkfs.reiser4 --version 2>&1'
run_pipe_section "fsck.reiser4 version" 'if command -v fsck.reiser4 >/dev/null 2>&1; then fsck.reiser4 -V 2>&1 || fsck.reiser4 --version 2>&1; elif command -v reiser4fsck >/dev/null 2>&1; then reiser4fsck -V 2>&1 || reiser4fsck --version 2>&1; else echo "fsck.reiser4 not present"; fi'
run_section "git rev-parse HEAD" git rev-parse HEAD
run_section "git status --short" git status --short
run_pipe_section "lsmod grep reiser4" 'lsmod | grep -E "(^| )reiser4" || true'
run_pipe_section "mount grep reiser4" 'mount | grep reiser4 || true'
run_section "losetup -a" losetup -a
run_pipe_section "/proc/filesystems grep reiser4" 'grep reiser4 /proc/filesystems || true'
