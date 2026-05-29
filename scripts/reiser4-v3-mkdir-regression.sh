#!/usr/bin/env bash
set -Eeuo pipefail

# Reiser4 V3 mkdir regression test for Ubuntu 24.04 / Linux 6.8-first work.
#
# This script is intentionally strict: mkdir, nested regular file IO, sync,
# clean unmount, and optional module unload are all treated as stability gates.
# It writes a self-contained command log plus dmesg snapshots under LOG_DIR.

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
RESULT=0

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

run sudo umount "$MNT"
LOOPDEV_TO_DETACH="$LOOPDEV"
run sudo losetup -d "$LOOPDEV_TO_DETACH"
LOOPDEV=""

if [ "$UNLOAD_MODULE" = "1" ]; then
	run sudo rmmod reiser4
fi

log "PASS: mkdir, nested file IO, sync, unmount, and any requested unload gate completed"
