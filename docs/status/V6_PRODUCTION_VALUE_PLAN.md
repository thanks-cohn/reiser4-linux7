# V6 Production-Value Plan

This document does **not** claim V6. It defines the structure required before a V6 production-value candidate can be considered.

## Test Matrix

Track every run with kernel version, compiler version, architecture, reiser4progs version, module commit, mount options, and storage backend.

Minimum matrix dimensions:

- Kernel versions: known-good, known-bad, and current development targets.
- Storage backends: loopback, disposable physical block device, virtual disk, and power-loss test device.
- Workloads: V1 lifecycle, V2 stress, V3 proof, source tree workloads, tar/unpack/delete, git clone/build/delete, large directory churn, and long remount/reboot cycles.
- Teardown: unmount, remount, `rmmod`, daemon/thread exit, and module reference count checks.

## Crash Consistency

Required before V6:

- Defined crash points for metadata updates, file writes, rename, unlink, and directory creation.
- Automated crash/replay harness.
- Post-crash mount behavior documented.
- Post-crash `fsck` / repair behavior documented.
- Expected data-loss boundaries documented.

## Power-Loss Testing

Required before V6:

- Repeatable power-cut test hardware or VM-backed forced power loss.
- Tests during write, rename, unlink, mkdir, sync, and remount.
- Evidence of mount, recovery, and integrity after repeated power loss.
- Clear list of workloads that remain unsafe after power loss.

## fsck / Recovery

Required before V6:

- Supported reiser4progs version matrix.
- `fsck` invocation documentation.
- Clean filesystem sanity run after every proof path where available.
- Corrupted-image recovery tests.
- Known unrecoverable states documented.

## Security Review

Required before V6:

- Audit of all user-controlled metadata parsing.
- Audit of bounds checks, integer overflow, reference counting, lifetime management, and folio/page interactions.
- Fuzzing plan for disk images and mount-time parsing.
- Review of all temporary compatibility shims and dangerous stubs.

## Supported Kernels

A supported kernel must have:

- Clean build logs.
- Passing V1, V2, and V3 proof logs.
- Clean unmount and `rmmod` evidence.
- No supported-path BUG, Oops, panic, warning explosion, NULL dereference, use-after-free, or stuck daemon threads.

## Unsupported Kernels

A kernel is unsupported if:

- The module does not build cleanly.
- The module cannot load.
- V1 fails.
- The proof path triggers kernel BUG, Oops, panic, warning explosion, NULL dereference, or use-after-free.
- Clean unmount or `rmmod` fails.

## Dangerous Stubs

The V6 process must track and burn down all occurrences reported by:

```text
tools/reiser4_danger_scan.sh
```

Every remaining `TODO`, `FIXME`, temporary bypass, unconditional success return, `BUG_ON`, panic path, or folio/shrink compatibility workaround must be classified as safe, unsafe, or removed.

## Release Discipline

Required before V6:

- Tagged releases only from passing commits.
- Release notes include exact kernel and reiser4progs versions.
- Known-good and known-bad kernel list.
- Known safe and unsafe workloads.
- Panic/Oops report template.
- Reproduction log template.

## Artifact / Release Policy

Required before V6:

- Source tags are the primary release artifact.
- Build artifacts must identify source commit, kernel headers, compiler, and configuration.
- No binary module should be published without matching source and proof logs.
- CI logs and proof-script output must be retained with each candidate release.
