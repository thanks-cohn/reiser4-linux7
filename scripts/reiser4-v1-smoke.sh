#!/usr/bin/env bash
set -u

cd "$(dirname "$0")/.."

echo "== Reiser4-NX v1-dev smoke test =="

sudo umount /mnt/reiser4-v1-smoke 2>/dev/null || true
sudo losetup -D 2>/dev/null || true
sudo rmmod reiser4 2>/dev/null || true

echo "[1/8] loading module"
sudo insmod ./reiser4.ko || exit 1

echo "[2/8] creating image"
rm -f /tmp/reiser4-v1-smoke.img
truncate -s 128M /tmp/reiser4-v1-smoke.img || exit 1

echo "[3/8] formatting"
mkfs.reiser4 -y -f /tmp/reiser4-v1-smoke.img

echo "[4/8] loop setup"
sudo losetup -fP /tmp/reiser4-v1-smoke.img || exit 1
LOOPDEV="$(losetup -a | grep /tmp/reiser4-v1-smoke.img | cut -d: -f1 | head -1)"

if [ -z "$LOOPDEV" ]; then
    echo "failed to find loop device"
    exit 1
fi

echo "[5/8] mounting $LOOPDEV"
sudo mkdir -p /mnt/reiser4-v1-smoke
sudo mount -t reiser4 "$LOOPDEV" /mnt/reiser4-v1-smoke || exit 1

echo "[6/8] writing"
echo "hello from reiser4 v1-dev" | sudo tee /mnt/reiser4-v1-smoke/test.txt >/dev/null || exit 1
sync

echo "[7/8] reading"
sudo cat /mnt/reiser4-v1-smoke/test.txt || exit 1

echo "[8/8] unmounting, known blocker may crash here"
sudo umount /mnt/reiser4-v1-smoke || true

echo
echo "== recent Reiser4 diagnostics =="
sudo dmesg -T | grep -E "BUMRUSH26|REISER4" | tail -120 || true
