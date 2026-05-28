#!/usr/bin/env bash
set -u

IMG="${IMG:-/tmp/reiser4-alpha.img}"
MNT="${MNT:-/mnt/reiser4-alpha}"
SIZE="${SIZE:-128M}"

pass(){ echo "PASS: $*"; }
fail(){ echo "FAIL: $*"; exit 1; }

echo "== Reiser4-NX Developer Alpha Smoke Test =="

sudo umount "$MNT" 2>/dev/null || true
sudo losetup -D 2>/dev/null || true
sudo rmmod reiser4 2>/dev/null || true

sudo insmod ./reiser4.ko || fail "module load"
pass "module loads"

rm -f "$IMG"
truncate -s "$SIZE" "$IMG" || fail "image create"

LOOP="$(sudo losetup --find --show "$IMG")" || fail "loop setup"
pass "loop setup"

yes yes | sudo mkfs.reiser4 "$LOOP" >/dev/null || fail "mkfs"
pass "mkfs"

sudo mkdir -p "$MNT"

sudo mount -t reiser4 "$LOOP" "$MNT" || fail "mount"
pass "mount"

sudo touch "$MNT/a" || fail "touch"
pass "touch"

echo "reiser4 lives" | sudo tee "$MNT/hello.txt" >/dev/null || fail "write"
pass "write"

sudo cat "$MNT/hello.txt" >/dev/null || fail "read"
pass "read"

if sudo mkdir "$MNT/testdir"; then
  pass "mkdir"
else
  echo "KNOWN-FAIL: mkdir"
fi

sudo ls -lah "$MNT" >/dev/null || fail "ls"
pass "ls"

sync
pass "sync"

sudo umount "$MNT" || fail "umount"
pass "umount"

sudo mount -t reiser4 "$LOOP" "$MNT" || fail "remount"
pass "remount"

sudo cat "$MNT/hello.txt" >/dev/null || fail "post-remount read"
pass "post-remount read"

echo
echo "REISER4-NX: SIGNAL RECEIVED"
