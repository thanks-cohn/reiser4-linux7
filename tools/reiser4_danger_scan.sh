#!/usr/bin/env bash
set -Eeuo pipefail

ROOT=${1:-.}

PATTERN='BUMRUSH|TEMPORARY|bypass|stub|TODO|FIXME|return[[:space:]]+0|EPERM|EINVAL|clear_inode|BUG_ON|panic|convert_ctail|shrink|folio'

if ! command -v rg >/dev/null 2>&1; then
	echo "reiser4_danger_scan: ripgrep (rg) is required" >&2
	exit 1
fi

rg \
	--line-number \
	--with-filename \
	--color=never \
	--hidden \
	-g '!**/.git/**' \
	-g '!**/*.o' \
	-g '!**/*.ko' \
	-g '!**/*.mod' \
	-g '!**/*.cmd' \
	-g '!**/Module.symvers' \
	-e "${PATTERN}" \
	"${ROOT}" || true
