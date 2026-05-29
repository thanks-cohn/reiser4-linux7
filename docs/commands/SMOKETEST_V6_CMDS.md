# smoketest_v6 cmds

Purpose: This document is the concise user-facing command guide for running Reiser4-NX V6 production-value smoke tests.

V6 candidate means evidence-worthy, not guaranteed safe for life files. These commands assume repo root is `~/reiser4-linux7` on Ubuntu 24.04 LTS.

## 1. Safety warning

- V6 candidate is not a guarantee.
- Do not use for only copies of important files.
- Do not use as root or `/home` until separate dedicated boot/root testing exists.
- Prefer loopback first, sacrificial disk second.
- Keep backups.

## 2. Install dependencies

```sh
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) git ripgrep kmod util-linux reiser4progs coreutils findutils
```

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

## 5. Check clean state

```sh
mount | grep reiser4 || true
findmnt | grep reiser4 || true
lsmod | grep reiser4 || true
losetup -a || true
ps -ef | grep -E 'ktxnmgrd|entd|reiser4' | grep -v grep || true
```

## 6. Clean old test state

```sh
sudo umount /tmp/reiser4-v1-mnt 2>/dev/null || true
sudo umount /mnt/reiser4-smoke 2>/dev/null || true
sudo losetup -D 2>/dev/null || true
sudo rmmod reiser4 2>/dev/null || true
```

If `reiser4` remains loaded or `ktxnmgrd` remains alive, reboot before V6 testing.

## 7. Quick V6 smoke run

```sh
sudo V6_QUICK=1 ./tests/run_v6_smoke_suite.sh
```

Quick mode is not V6 proof. It is a fast sanity check.

## 8. Full V6 smoke run

```sh
sudo ./tests/run_v6_smoke_suite.sh
```

This can take a long time and may run very heavy workloads.

## 9. Individual V6 tests

| # | Test | Command | Proves |
|---|------|---------|--------|
| 1 | clean build matrix | `sudo ./tests/v6_smoke_clean_build_matrix.sh` | Builds `reiser4.ko` against current headers and records compiler/module evidence. |
| 2 | module lifecycle 100 | `sudo ./tests/v6_smoke_module_lifecycle_100.sh` | Repeated `insmod`/`rmmod` leaves no stuck refs. |
| 3 | mkfs/mount/unmount 500 | `sudo ./tests/v6_smoke_mkfs_mount_unmount_500.sh` | Repeated image mkfs, mount, root stat, unmount, loop detach, and unload. |
| 4 | full V1 100 | `sudo ./tests/v6_smoke_full_v1_100.sh` | Repeated basic create/write/read/rename/delete/remount/verify lifecycle. |
| 5 | V3 proof 30 | `sudo ./tests/v6_smoke_v3_proof_30.sh` | Existing V3 proof repeats with artifact trails. |
| 6 | teardown after failure 100 | `sudo ./tests/v6_smoke_teardown_after_failure_100.sh` | Deliberate failures do not leave dirty module/thread/loop state. |
| 7 | fsck clean and dirty | `sudo ./tests/v6_smoke_fsck_clean_and_dirty.sh` | `fsck.reiser4` behavior is captured after clean and dirty-style shutdowns. |
| 8 | hash manifest integrity 100k | `sudo ./tests/v6_smoke_hash_manifest_integrity_100k.sh` | Many files survive remount with matching size/hash manifest. |
| 9 | directory scale 1m | `sudo ./tests/v6_smoke_directory_scale_1m.sh` | Large directory create/list/stat/delete behavior is repeatable. |
| 10 | nested tree depth | `sudo ./tests/v6_smoke_nested_tree_depth.sh` | Deep trees survive operations, remount, and fsck. |
| 11 | rename/delete storm | `sudo ./tests/v6_smoke_rename_delete_storm.sh` | Thousands of metadata churn operations avoid corruption/stuck state. |
| 12 | parallel writers | `sudo ./tests/v6_smoke_parallel_writers.sh` | Concurrent writers/readers avoid mismatches and hangs. |
| 13 | large file streaming | `sudo ./tests/v6_smoke_large_file_streaming.sh` | Large file write/sync/read/remount verification works. |
| 14 | small file pressure | `sudo ./tests/v6_smoke_small_file_pressure.sh` | Many tiny files survive sync/remount/fsck/verify. |
| 15 | real workload kernel tree | `sudo ./tests/v6_smoke_real_workload_kernel_tree.sh` | Kernel-tree-like copy/unpack/delete workload survives remount verification. |
| 16 | real workload git | `sudo ./tests/v6_smoke_real_workload_git.sh` | Local git clone/status/add/commit/rename/fsck works across remount. |
| 17 | ENOSPC/inode exhaustion | `sudo ./tests/v6_smoke_enospc_inode_exhaustion.sh` | Full-filesystem behavior is safe and recoverable. |
| 18 | long filename boundaries | `sudo ./tests/v6_smoke_long_filename_boundaries.sh` | Name lengths work safely or fail safely with recorded errno. |
| 19 | powercut sim loopback | `sudo ./tests/v6_smoke_powercut_sim_loopback.sh` | Safe loopback dirty-interruption simulation does not silently corrupt stable data. |
| 20 | 7 day soak | `sudo ./tests/v6_smoke_7_day_soak.sh` | Long mixed workload avoids dmesg danger, corruption, stuck refs, and fsck failures. |

## 10. Useful reduced-run examples

```sh
V6_CYCLES=3 sudo ./tests/v6_smoke_module_lifecycle_100.sh
V6_CYCLES=10 sudo ./tests/v6_smoke_mkfs_mount_unmount_500.sh
V6_FILE_COUNT=1000 sudo ./tests/v6_smoke_hash_manifest_integrity_100k.sh
V6_ENTRY_COUNT=10000 sudo ./tests/v6_smoke_directory_scale_1m.sh
V6_LARGE_SIZE=128M sudo ./tests/v6_smoke_large_file_streaming.sh
V6_SOAK_HOURS=1 sudo ./tests/v6_smoke_7_day_soak.sh
```

## 11. How to read final status

`V6_SMOKE_STATUS=CANDIDATE` means the suite passed its configured run.

`V6_SMOKE_STATUS=BLOCKED_BY_*` means do not claim V6.

Statuses:

- `BLOCKED_BY_BUILD`
- `BLOCKED_BY_MODULE`
- `BLOCKED_BY_MKFS_MOUNT`
- `BLOCKED_BY_V1`
- `BLOCKED_BY_V3`
- `BLOCKED_BY_TEARDOWN`
- `BLOCKED_BY_FSCK`
- `BLOCKED_BY_CORRUPTION`
- `BLOCKED_BY_DMESG`
- `BLOCKED_BY_SCALE`
- `BLOCKED_BY_REAL_WORKLOAD`
- `BLOCKED_BY_ENOSPC`
- `BLOCKED_BY_LONG_NAMES`
- `BLOCKED_BY_SOAK`

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

## 13. Definition of V6 candidate

Reiser4-NX V6 production-value candidate requires:

- clean build;
- clean module lifecycle;
- repeated mkfs/mount/unmount;
- full V1 repeated pass;
- V3 proof repeated pass;
- teardown after failures;
- fsck clean/dirty behavior;
- manifest integrity;
- scale tests;
- real workload tests;
- ENOSPC safety;
- long filename boundary safety;
- soak test;
- no silent corruption;
- no dmesg danger;
- no stuck module/kernel thread/loop device.

This still does not equal broad production deployment.
It means Reiser4-NX is ready for serious outside testing and sacrificial-disk trials.
