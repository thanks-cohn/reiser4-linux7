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
