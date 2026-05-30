#!/usr/bin/env bash
set -euo pipefail

IMG="${IMG:-/tmp/reiser4-smoke.img}"
MNT="${MNT:-/mnt/reiser4-smoke}"

sudo rm -f "$IMG"
sudo mkdir -p "$MNT"

dd if=/dev/zero of="$IMG" bs=1M count=512 status=none
mkfs.reiser4 -y -f "$IMG"

sudo mount -o loop -t reiser4 "$IMG" "$MNT"

echo "hello reiser4" | sudo tee "$MNT/hello.txt" >/dev/null
sudo mkdir "$MNT/dir1"
echo "inside" | sudo tee "$MNT/dir1/file.txt" >/dev/null

sync

cat "$MNT/hello.txt"
cat "$MNT/dir1/file.txt"

sudo umount "$MNT"

sudo mount -o loop -t reiser4 "$IMG" "$MNT"
cat "$MNT/hello.txt"
cat "$MNT/dir1/file.txt"
sudo umount "$MNT"

echo "PASS smoke_reiser4_loop"
