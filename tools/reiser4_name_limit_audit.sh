#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATTERN='NAME_MAX|PATH_MAX|QSTR|qstr|dentry|d_name|name\.len|namelen|name_len|strlen|strnlen|memcpy|strncpy|ENAMETOOLONG|EOVERFLOW|filename|lookup|mkdir|rename|unlink|link|dirent|directory item'

cd "${ROOT_DIR}"

if command -v rg >/dev/null 2>&1; then
	rg -n --no-heading \
		--glob '!.git/' \
		--glob '!artifacts/' \
		--glob '!*.o' \
		--glob '!*.ko' \
		--glob '!*.mod' \
		--glob '!*.cmd' \
		--glob '!Module.symvers' \
		--glob '!modules.order' \
		-e "${PATTERN}" .
else
	grep -RInE \
		--exclude='*.o' \
		--exclude='*.ko' \
		--exclude='*.mod' \
		--exclude='*.cmd' \
		--exclude='Module.symvers' \
		--exclude='modules.order' \
		--exclude-dir='.git' \
		--exclude-dir='artifacts' \
		"${PATTERN}" .
fi
