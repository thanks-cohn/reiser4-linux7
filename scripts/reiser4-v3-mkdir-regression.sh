#!/usr/bin/env bash
set -Eeuo pipefail

# Reiser4 V3 mkdir regression test for Ubuntu 24.04 / Linux 6.8-first work.
#
# This is a focused regression, not the full V3 proof. It gates mkdir plus
# nested file IO, rename/delete, remount verification, clean unmount, optional
# module unload, and a dangerous-kernel-message dmesg scan.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG="${IMG:-/tmp/reiser4-v3-mkdir.img}"
MNT="${MNT:-/mnt/reiser4-v3-mkdir}"
SIZE="${SIZE:-256M}"
MODULE="${MODULE:-$ROOT_DIR/reiser4.ko}"
KEEP_IMAGE="${KEEP_IMAGE:-0}"
UNLOAD_MODULE="${UNLOAD_MODULE:-0}"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/artifacts/reiser4-v3-mkdir-$(date -u +%Y%m%dT%H%M%SZ)}"
RUN_LOG="$LOG_DIR/run.log"
DMESG_BEFORE="$LOG_DIR/dmesg.before.log"
DMESG_AFTER="$LOG_DIR/dmesg.after.log"
LOOPDEV=""
DMESG_PATTERN='BUG|Oops|panic|null pointer|NULL pointer|WARNING|use-after-free'

mkdir -p "$LOG_DIR"
exec > >(tee -a "$RUN_LOG") 2>&1

log() {
	printf '\n[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

run() {
	log "+ $*"
	"$@"
}

require_cmd() {
	local cmd="$1"
	log "+ command -v $cmd"
	if ! command -v "$cmd"; then
		log "ERROR: required command is missing: $cmd"
		exit 2
	fi
}

capture_dmesg() {
	local target="$1"
	if sudo dmesg -T >"$target" 2>&1; then
		log "captured dmesg: $target"
	else
		log "WARNING: unable to capture dmesg into $target"
	fi
}

clear_dmesg_if_permitted() {
	log "+ sudo dmesg -C"
	if sudo dmesg -C >/dev/null 2>&1; then
		log "cleared dmesg for focused regression window"
	else
		log "WARNING: unable to clear dmesg; scan will include older kernel messages"
	fi
}

scan_dmesg() {
	local target="$1"
	if grep -Eiq "$DMESG_PATTERN" "$target"; then
		log "ERROR: dangerous dmesg text matched pattern: $DMESG_PATTERN"
		grep -Ein "$DMESG_PATTERN" "$target" | tail -100 || true
		return 1
	fi
}

cleanup() {
	local status=$?
	set +e
	log "cleanup: begin (status=$status)"
	if mountpoint -q "$MNT"; then
		sudo umount "$MNT"
		local umount_status=$?
		log "cleanup: umount status=$umount_status"
		if [ "$umount_status" -ne 0 ] && [ "$status" -eq 0 ]; then
			status=$umount_status
		fi
	fi
	if [ -n "$LOOPDEV" ]; then
		sudo losetup -d "$LOOPDEV"
		log "cleanup: detached $LOOPDEV status=$?"
	fi
	if [ "$UNLOAD_MODULE" = "1" ]; then
		sudo rmmod reiser4
		local rmmod_status=$?
		log "cleanup: rmmod reiser4 status=$rmmod_status"
		if [ "$rmmod_status" -ne 0 ] && [ "$status" -eq 0 ]; then
			status=$rmmod_status
		fi
	fi
	capture_dmesg "$DMESG_AFTER"
	scan_dmesg "$DMESG_AFTER"
	local scan_status=$?
	if [ "$scan_status" -ne 0 ] && [ "$status" -eq 0 ]; then
		status=$scan_status
	fi
	if [ "$KEEP_IMAGE" != "1" ]; then
		rm -f "$IMG"
		log "cleanup: removed image $IMG"
	else
		log "cleanup: kept image $IMG"
	fi
	log "logs are in $LOG_DIR"
	exit "$status"
}
trap cleanup EXIT

log "Reiser4 V3 mkdir regression test"
log "root=$ROOT_DIR"
log "image=$IMG size=$SIZE mount=$MNT module=$MODULE"
run uname -a
run id
require_cmd mkfs.reiser4
require_cmd losetup
clear_dmesg_if_permitted
capture_dmesg "$DMESG_BEFORE"

if ! grep -qw reiser4 /proc/filesystems; then
	if [ ! -f "$MODULE" ]; then
		log "ERROR: reiser4 is not registered and module is missing: $MODULE"
		exit 2
	fi
	run sudo insmod "$MODULE"
else
	log "reiser4 already registered in /proc/filesystems"
fi

run sudo mkdir -p "$MNT"
run rm -f "$IMG"
run truncate -s "$SIZE" "$IMG"

log "+ mkfs.reiser4 -f $IMG"
printf 'Yes\n' | mkfs.reiser4 -f "$IMG"

LOOPDEV="$(sudo losetup --find --show "$IMG")"
log "loopdev=$LOOPDEV"
run sudo mount -t reiser4 "$LOOPDEV" "$MNT"

run sudo mkdir "$MNT/dir1"
log "+ write nested file"
printf 'inside mkdir regression\n' | sudo tee "$MNT/dir1/file.txt" >/dev/null
run sync
run sudo test -d "$MNT/dir1"
run sudo test -f "$MNT/dir1/file.txt"
log "+ read nested file"
sudo cat "$MNT/dir1/file.txt"

run sudo mv "$MNT/dir1/file.txt" "$MNT/dir1/file.renamed"
run sudo test -f "$MNT/dir1/file.renamed"
run sudo rm "$MNT/dir1/file.renamed"
run sudo test ! -e "$MNT/dir1/file.renamed"
log "+ recreate marker for remount verification"
printf 'remount marker\n' | sudo tee "$MNT/dir1/remount-marker.txt" >/dev/null
run sync

run sudo umount "$MNT"
run sudo mount -t reiser4 "$LOOPDEV" "$MNT"
run sudo test -d "$MNT/dir1"
run sudo test -f "$MNT/dir1/remount-marker.txt"
log "+ read remount marker"
sudo cat "$MNT/dir1/remount-marker.txt"
run sync
run sudo umount "$MNT"
LOOPDEV_TO_DETACH="$LOOPDEV"
run sudo losetup -d "$LOOPDEV_TO_DETACH"
LOOPDEV=""

if [ "$UNLOAD_MODULE" = "1" ]; then
	run sudo rmmod reiser4
fi

log "PASS: mkdir, rename, delete, remount verification, unmount, and any requested unload gate completed"
