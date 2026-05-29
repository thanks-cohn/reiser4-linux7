# smoketest_v3 cmds

Purpose: This document is the user-facing command guide for running Reiser4-NX V3 personal readiness smoke tests on Ubuntu 24.04 LTS.

## 1. Safety warning

- Do not use Reiser4-NX as `/home`.
- Do not use Reiser4-NX as root.
- Do not use it for only copies of important files.
- Start with loopback images.
- Use sacrificial disks only after loopback tests pass repeatedly.

## 2. Install basic test dependencies

```sh
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) git ripgrep kmod util-linux reiser4progs
```

Package names may vary if `reiser4progs` is manually installed or provided outside the Ubuntu repositories available to the lab VM.

## 3. Enter repo and update

```sh
cd ~/reiser4-linux7
git pull --rebase origin master
git status --short
git log --oneline --decorate --max-count=12
```

## 4. Make scripts executable

```sh
chmod +x tests/*.sh tools/*.sh scripts/*.sh 2>/dev/null || true
chmod +x tests/lib/*.sh 2>/dev/null || true
```

## 5. Check for dirty old state before testing

```sh
mount | grep reiser4 || true
findmnt | grep reiser4 || true
lsmod | grep reiser4 || true
losetup -a || true
ps -ef | grep -E 'ktxnmgrd|entd|reiser4' | grep -v grep || true
```

If `reiser4` is already loaded or loop devices are stuck, smoke tests may fail with misleading `File exists` or module-in-use errors.

## 6. Clean old test state

```sh
sudo umount /tmp/reiser4-v1-mnt 2>/dev/null || true
sudo umount /mnt/reiser4-smoke 2>/dev/null || true
sudo losetup -D 2>/dev/null || true
sudo rmmod reiser4 2>/dev/null || true
```

Then re-check:

```sh
mount | grep reiser4 || true
lsmod | grep reiser4 || true
losetup -a || true
ps -ef | grep -E 'ktxnmgrd|entd|reiser4' | grep -v grep || true
```

If `rmmod` fails and `ktxnmgrd` remains alive, reboot the lab VM before continuing.

## 7. Build the module

```sh
sudo dmesg -C 2>/dev/null || true
./tests/smoke_build_module.sh
```

Manual fallback:

```sh
make -C /lib/modules/$(uname -r)/build M="$PWD" clean
make -C /lib/modules/$(uname -r)/build M="$PWD" modules -j"$(nproc)"
ls -lh reiser4.ko
```

## 8. Run the smoke tests one by one

| # | Test | Command | What it proves | If it fails |
|---|------|---------|----------------|-------------|
| 1 | `smoke_build_module.sh` | `./tests/smoke_build_module.sh` | Builds reiser4.ko against current kernel headers. Artifact: `artifacts/smoke_build_module-<timestamp>/`. | Kernel headers/build are blocked. |
| 2 | `smoke_module_lifecycle.sh` | `sudo ./tests/smoke_module_lifecycle.sh` | insmod, /proc/filesystems, rmmod without mounting. Artifact: `artifacts/smoke_module_lifecycle-<timestamp>/`. | Preloaded/stuck module or registration/unload issue. |
| 3 | `smoke_mkfs_image.sh` | `sudo ./tests/smoke_mkfs_image.sh` | Creates a fresh loopback image with mkfs.reiser4. Artifact: `artifacts/smoke_mkfs_image-<timestamp>/`. | reiser4progs/mkfs/image setup is blocked. |
| 4 | `smoke_mount_root_stat_unmount.sh` | `sudo ./tests/smoke_mount_root_stat_unmount.sh` | Formats, mounts, stats root, unmounts, unloads. Artifact: `artifacts/smoke_mount_root_stat_unmount-<timestamp>/`. | Basic mount or cleanup is blocked. |
| 5 | `smoke_regular_file_create.sh` | `sudo ./tests/smoke_regular_file_create.sh` | Creates a normal file on mounted Reiser4. Artifact: `artifacts/smoke_regular_file_create-<timestamp>/`. | Regular file create is blocked. |
| 6 | `smoke_regular_file_write_read.sh` | `sudo ./tests/smoke_regular_file_write_read.sh` | Writes known bytes, syncs, reads back hash. Artifact: `artifacts/smoke_regular_file_write_read-<timestamp>/`. | Regular file IO is blocked. |
| 7 | `smoke_regular_file_remount_verify.sh` | `sudo ./tests/smoke_regular_file_remount_verify.sh` | Writes file, unmounts, remounts, verifies hash. Artifact: `artifacts/smoke_regular_file_remount_verify-<timestamp>/`. | Persistence/remount verify is blocked. |
| 8 | `smoke_rename_file.sh` | `sudo ./tests/smoke_rename_file.sh` | Creates and renames a file. Artifact: `artifacts/smoke_rename_file-<timestamp>/`. | Rename/link state is blocked. |
| 9 | `smoke_delete_file.sh` | `sudo ./tests/smoke_delete_file.sh` | Creates, deletes, remounts, verifies gone. Artifact: `artifacts/smoke_delete_file-<timestamp>/`. | Unlink/persistence is blocked. |
| 10 | `smoke_mkdir_basic.sh` | `sudo ./tests/smoke_mkdir_basic.sh` | Attempts one directory create. Artifact: `artifacts/smoke_mkdir_basic-<timestamp>/`. | Current known EPERM blocker may be hit. |
| 11 | `smoke_nested_directories.sh` | `sudo ./tests/smoke_nested_directories.sh` | Creates a/b/c/d/e and verifies after remount. Artifact: `artifacts/smoke_nested_directories-<timestamp>/`. | Directory nesting is blocked. |
| 12 | `smoke_directory_many_entries_small.sh` | `sudo ./tests/smoke_directory_many_entries_small.sh` | Creates 100 files in one directory. Artifact: `artifacts/smoke_directory_many_entries_small-<timestamp>/`. | Directory entry handling is blocked. |
| 13 | `smoke_sync_pressure_small.sh` | `sudo ./tests/smoke_sync_pressure_small.sh` | Creates/syncs 100 small files. Artifact: `artifacts/smoke_sync_pressure_small-<timestamp>/`. | Writeback/sync cleanliness is blocked. |
| 14 | `smoke_repeated_mount_unmount_10.sh` | `sudo ./tests/smoke_repeated_mount_unmount_10.sh` | Mounts/unmounts same image 10 times. Artifact: `artifacts/smoke_repeated_mount_unmount_10-<timestamp>/`. | Loop/mount/reference cleanup is blocked. |
| 15 | `smoke_module_unload_after_filesystem_use.sh` | `sudo ./tests/smoke_module_unload_after_filesystem_use.sh` | Writes/reads/unmounts then rmmod. Artifact: `artifacts/smoke_module_unload_after_filesystem_use-<timestamp>/`. | Module ref/thread cleanup is blocked. |
| 16 | `smoke_failed_operation_teardown.sh` | `sudo ./tests/smoke_failed_operation_teardown.sh` | Triggers expected failure and checks cleanup. Artifact: `artifacts/smoke_failed_operation_teardown-<timestamp>/`. | Failed ops leave module/loop/thread stuck. |
| 17 | `smoke_dmesg_cleanliness.sh` | `sudo ./tests/smoke_dmesg_cleanliness.sh` | Scans dmesg for danger terms. Artifact: `artifacts/smoke_dmesg_cleanliness-<timestamp>/`. | Kernel emitted danger signal. |
| 18 | `smoke_fsck_after_clean_unmount.sh` | `sudo ./tests/smoke_fsck_after_clean_unmount.sh` | Runs fsck.reiser4 after clean unmount. Artifact: `artifacts/smoke_fsck_after_clean_unmount-<timestamp>/`. | On-disk consistency is blocked. |
| 19 | `smoke_v3_short_stress.sh` | `sudo ./tests/smoke_v3_short_stress.sh` | Nested dirs, 500 files, rename/delete storm, remount verify. Artifact: `artifacts/smoke_v3_short_stress-<timestamp>/`. | Stress workload is blocked. |
| 20 | `smoke_v3_repeat_from_clean_boot.sh` | `sudo ./tests/smoke_v3_repeat_from_clean_boot.sh` | Records boot time and repeats short V3 validation. Artifact: `artifacts/smoke_v3_repeat_from_clean_boot-<timestamp>/`. | Clean-boot repeat is blocked. |

## 9. Recommended staged run order

Stage 0: Build only

```sh
./tests/smoke_build_module.sh
```

Stage 1: Module lifecycle only

```sh
sudo ./tests/smoke_module_lifecycle.sh
```

Stage 2: mkfs/mount/root stat/unmount

```sh
sudo ./tests/smoke_mkfs_image.sh
sudo ./tests/smoke_mount_root_stat_unmount.sh
```

Stage 3: regular file operations

```sh
sudo ./tests/smoke_regular_file_create.sh
sudo ./tests/smoke_regular_file_write_read.sh
sudo ./tests/smoke_regular_file_remount_verify.sh
sudo ./tests/smoke_rename_file.sh
sudo ./tests/smoke_delete_file.sh
```

Stage 4: directory operations

```sh
sudo ./tests/smoke_mkdir_basic.sh
sudo ./tests/smoke_nested_directories.sh
sudo ./tests/smoke_directory_many_entries_small.sh
```

Stage 5: pressure and teardown

```sh
sudo ./tests/smoke_sync_pressure_small.sh
sudo ./tests/smoke_repeated_mount_unmount_10.sh
sudo ./tests/smoke_module_unload_after_filesystem_use.sh
sudo ./tests/smoke_failed_operation_teardown.sh
```

Stage 6: cleanliness and fsck

```sh
sudo ./tests/smoke_dmesg_cleanliness.sh
sudo ./tests/smoke_fsck_after_clean_unmount.sh
```

Stage 7: short V3 stress

```sh
sudo ./tests/smoke_v3_short_stress.sh
```

Stage 8: reboot repeat

```sh
sudo reboot
```

Then after reboot:

```sh
cd ~/reiser4-linux7
sudo ./tests/smoke_v3_repeat_from_clean_boot.sh
```

## 10. One-command suite

```sh
sudo ./tests/run_v3_personal_smoke_suite.sh
```

This is the convenient command, but if it fails, rerun individual stages to isolate the blocker.

## 11. How to read result summaries

Each test writes `artifacts/<test-name>-<timestamp>/summary.txt`.

Example:

```text
TEST=smoke_mkdir_basic
RESULT=FAIL
FAILED_STAGE=mkdir
GIT_HEAD=<sha>
KERNEL=<uname>
MODULE_LOADED_BEFORE=0
MODULE_UNLOADED_AFTER_CLEANUP=0
KTXNMGRD_ALIVE_AFTER=1
LOOP_STUCK_AFTER=1
DMESG_DANGER=0
ARTIFACT_DIR=artifacts/smoke_mkdir_basic-...
```

- `RESULT=PASS` means the test passed.
- `RESULT=FAIL` means do not claim readiness.
- `MODULE_UNLOADED_AFTER_CLEANUP=0` means module lifecycle is still dirty.
- `KTXNMGRD_ALIVE_AFTER=1` means reboot may be required.
- `LOOP_STUCK_AFTER=1` means cleanup did not finish.

## 12. What to paste when asking for help

```sh
LATEST="$(ls -td artifacts/* 2>/dev/null | head -1)"
echo "LATEST=$LATEST"
cat "$LATEST/summary.txt" 2>/dev/null || true
cat "$LATEST/state-after-cleanup.txt" 2>/dev/null || true
cat "$LATEST/dmesg-filtered.txt" 2>/dev/null || true
git log --oneline --decorate --max-count=8
uname -a
```

## 13. Known current blockers

- `mkdir` may fail with `EPERM` until fixed.
- Failed smoke tests may expose teardown/module reference bugs.
- `ktxnmgrd` may remain alive after failure.
- Loop devices may remain attached to deleted images.
- `insmod: File exists` usually means the module was already loaded, not that the new test truly reached the intended stage.
- V3 personal readiness requires all required smoke tests to pass cleanly.

## 14. Status meaning

`V3_PERSONAL_SMOKE_STATUS=READY_TO_TRY` means all required V3 personal smoke tests passed on loopback from a clean boot, no dmesg danger, no stuck module, no stuck `ktxnmgrd`/`entd`, no stuck loop device.

`V3_PERSONAL_SMOKE_STATUS=BLOCKED_BY_MKDIR` means do not try personal use yet. Directory creation still fails.

`V3_PERSONAL_SMOKE_STATUS=BLOCKED_BY_TEARDOWN` means do not try personal use yet. Failed operations can poison module cleanup.

`V3_PERSONAL_SMOKE_STATUS=BLOCKED_BY_DMESG` means do not try personal use yet. Kernel warnings/errors appeared.

Other blocked statuses identify the first foundational gate: build, module lifecycle, mkfs, mount, file read/write, fsck, or stress.

## 15. Definition of ready to try

Reiser4-NX V3 personal experimental loopback use is ready to try only when:

- build passes;
- module lifecycle passes;
- mkfs/mount/root stat/unmount passes;
- regular file create/write/read/remount verify passes;
- mkdir passes;
- nested directories pass;
- many small entries pass;
- sync pressure passes;
- repeated mount/unmount passes;
- module unload after filesystem use passes;
- failed operation teardown passes;
- dmesg cleanliness passes;
- fsck after clean unmount passes;
- short V3 stress passes;
- repeat from clean boot passes.

This still does not mean production.
This still does not mean `/home`.
This still does not mean life files.
It means controlled personal experimental loopback use may begin.
