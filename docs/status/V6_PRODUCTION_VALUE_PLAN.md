# V6 Production-Value Plan

This document does **not** claim V6. It defines the work required before a production-value candidate can be considered.

## Supported Kernel Matrix

A supported kernel entry must include:

- Exact `uname -a`.
- Kernel config source or package identifier.
- Architecture.
- Compiler and binutils versions.
- Reiser4 module commit.
- Passing V1, V2, and V3 gate artifacts.
- Clean unmount/remount/`rmmod` evidence.

Unsupported kernels must remain listed with the reason: build failure, load failure, V1 failure, V3 failure, crash, dirty teardown, or unreviewed warning.

## CI / Build Matrix

V6 needs reproducible CI that covers:

- Clean module build against every supported kernel.
- Warnings-as-actionable build log review.
- Script shell checks for `scripts/`, `tests/`, and `tools/`.
- Artifact upload for logs, `dmesg`, environment reports, and failure bundles.
- Optional destructive-test jobs isolated from normal CI.

## fsck / Recovery Story

V6 requires a documented recovery path:

- Supported `mkfs.reiser4` and `fsck.reiser4` versions.
- Expected clean-fs `fsck` output after proof scripts.
- Corrupted-image repair tests.
- Post-crash mount and fsck behavior.
- Known unrecoverable states and user-facing instructions.

## Crash Consistency Testing

Required crash-consistency coverage:

- `mkdir`, create, write, rename, unlink, sync, and remount crash points.
- Forced crash/replay harness for loopback or VM disks.
- Verification of metadata and file contents after recovery.
- Explicit documentation of expected data-loss boundaries.

## Power-Loss Testing

Required power-loss coverage:

- Repeatable VM hard-poweroff or hardware power-cut harness.
- Power loss during writeback, metadata update, rename, unlink, mkdir, sync, mount, and unmount.
- Post-power-loss mount, fsck, and workload validation.
- Clear list of workloads that remain unsafe after power loss.

## Security Review

Required review areas:

- Disk metadata parsing and mount-time trust boundaries.
- Integer overflow and bounds checking.
- Reference counting and lifetime rules.
- Folio/page/private-data ownership.
- Locking, transaction, and daemon teardown.
- Fuzzing of disk images and mount/recovery paths.

## Temporary Stub Removal

Before V6, every dangerous marker reported by `tools/reiser4_danger_scan.sh` must be removed or classified. This includes `BUMRUSH`, `TEMPORARY`, bypasses, stubs, `TODO`, `FIXME`, suspicious unconditional `return 0`, `EPERM`, `EINVAL`, `clear_inode`, `BUG_ON`, `panic`, `convert_ctail`, `assign_conversion_mode`, shrinker, and folio compatibility markers.

## Known Safe Workloads

A workload can be called safe only after it has passing artifacts across the supported matrix. Candidate safe-workload categories:

- Disposable loopback smoke tests.
- Many-small-file create/read/rename/delete cycles.
- Source tree unpack/build/delete cycles.
- Archive extract/delete cycles.
- Git clone/status/delete cycles.

## Known Unsafe Workloads

Unsafe until proven otherwise:

- Valuable data.
- Unsupported kernels.
- Unbounded production services.
- Power-loss scenarios without recovery evidence.
- Any ctail conversion workload that can reproduce the known NULL-deref path.
- Any workload that leaves lingering module refs, daemon threads, dirty pages, or unreviewed warnings.

## Release Discipline

V6 candidate releases require:

- Tagged source release.
- Exact source commit, kernel matrix, compiler matrix, and reiser4progs matrix.
- Retained V1/V2/V3/V6 artifacts.
- Published safe/unsafe workload boundaries.
- Published failure-report template and recovery instructions.
- No binary module without matching source, build metadata, and proof logs.

## Large Filename / True Name Requirements

V6 cannot claim production value while long-name behavior is unknown, unsafe, or
only described as aspiration. Reiser4-NX must preserve the long-name dream by
proving the safe boundaries first.

Required evidence before any production-value claim:

- Normal filename boundary tests around common Linux component limits, including
  safe behavior at and beyond 255-byte components.
- Current observed Reiser4-NX filename limits from privileged loopback probes,
  including remount verification and dmesg scans.
- Honest native large-name feasibility research covering kernel, VFS, dentry,
  `qstr`, userspace, backup, recovery, and tooling constraints.
- No native large POSIX name mode unless it is explicitly experimental,
  default-off, mount-option gated, and protected by tests.
- True-name metadata design for a POSIX-visible safe name plus a durable
  Reiser4-NX true name of at least 4000 characters.
- Export/import manifest strategy so movement to ext4, XFS, Btrfs, ZFS, or other
  filesystems creates safe shortened names while preserving full true names in a
  manifest.
- Backup, restore, remount, fsck/recovery, and damaged-image drills proving true
  names are preserved or failures are reported clearly.
- No production-value claim if long-name behavior is unknown, untested,
  unrecoverable, or capable of creating false confidence.

## V6 Smoke Gates

V6 production-value candidate status requires these tests, or reviewed successor equivalents, to pass with retained artifacts, summaries, dmesg scans, cleanup state, fsck output where applicable, and git/kernel/reiser4progs version evidence:

1. `tests/v6_smoke_clean_build_matrix.sh`
2. `tests/v6_smoke_module_lifecycle_100.sh`
3. `tests/v6_smoke_mkfs_mount_unmount_500.sh`
4. `tests/v6_smoke_full_v1_100.sh`
5. `tests/v6_smoke_v3_proof_30.sh`
6. `tests/v6_smoke_teardown_after_failure_100.sh`
7. `tests/v6_smoke_powercut_sim_loopback.sh`
8. `tests/v6_smoke_fsck_clean_and_dirty.sh`
9. `tests/v6_smoke_hash_manifest_integrity_100k.sh`
10. `tests/v6_smoke_directory_scale_1m.sh`
11. `tests/v6_smoke_nested_tree_depth.sh`
12. `tests/v6_smoke_rename_delete_storm.sh`
13. `tests/v6_smoke_parallel_writers.sh`
14. `tests/v6_smoke_large_file_streaming.sh`
15. `tests/v6_smoke_small_file_pressure.sh`
16. `tests/v6_smoke_real_workload_kernel_tree.sh`
17. `tests/v6_smoke_real_workload_git.sh`
18. `tests/v6_smoke_enospc_inode_exhaustion.sh`
19. `tests/v6_smoke_long_filename_boundaries.sh`
20. `tests/v6_smoke_7_day_soak.sh`

Passing these smoke gates still does not equal broad production deployment. It only supports a production-value candidate claim for serious outside testing and sacrificial-disk trials.
