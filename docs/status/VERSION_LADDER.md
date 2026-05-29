# Reiser4-Linux7 Version Ladder

This ladder defines what each project milestone means. A milestone is not real unless the matching proof script exists, passes, and the accompanying `dmesg` evidence shows no kernel BUG, Oops, panic, warning explosion, NULL dereference, or stuck module/thread teardown in the supported path.

## V0 Alive

**Target:** prove the filesystem is alive enough for minimal loopback use.

Required evidence:

- Kernel module builds as an out-of-tree module.
- `reiser4.ko` loads.
- `mkfs.reiser4` formats a loopback image.
- Filesystem mounts.
- Regular file create/write/read works.

## V1 Basic Lifecycle

**Target:** prove one complete basic filesystem lifecycle.

Required operation sequence:

```text
mkfs -> mount -> mkdir -> create -> write -> read -> rename -> delete -> sync -> unmount -> remount -> verify -> unmount -> rmmod
```

Required proof:

- `tests/smoke_reiser4_v1.sh` passes.
- Failure path captures `dmesg` evidence.
- No supported-path BUG, Oops, panic, warning explosion, NULL dereference, or stuck module reference is observed.

## V2 Stress-Hardened Lab

**Target:** prove repeated lab stress on loopback without immediate lifecycle regressions.

Required evidence:

- 1000 basic filesystem operation loops.
- 50 mount/remount cycles.
- Nested directory operations during the stress path.
- Many small file create/rename/delete cycles.
- No kernel BUG, Oops, panic, warning explosion, or stuck module refs.

Required proof:

- `tests/stress_reiser4_v2.sh 1000` passes.
- `dmesg` evidence is checked after the run.

## V3 Personal Experimental Use

**Target:** make loopback-only personal experimental use a guaranteed target, not a claim.

Required evidence:

- Overnight-capable stress on loopback.
- Nested directories.
- Many small files.
- Medium files.
- Rename/delete storms.
- Remount verification.
- `fsck` / reiser4progs sanity checks if available.
- Sacrificial disk path documented before any block-device testing.
- No known immediate corruption path in the supported test path.
- No kernel BUG, Oops, panic, warning explosion, NULL dereference, or use-after-free in the supported test path.

Required proof:

- `tests/prove_reiser4_v3.sh` passes.
- V1 and V2 gates pass inside the V3 proof wrapper.
- Final summary explicitly says PASS.

## V4 Daily Driver Candidate

**Target:** prove backed-up dedicated-machine viability before normal use is considered.

Required evidence:

- 7-day backed-up dedicated-machine run.
- Source tree workloads.
- Tar/unpack/delete cycles.
- Git clone/build/delete cycles.
- Large directories.
- Repeated reboot/remount checks.
- Clear list of still-unsupported workloads.

## V5 Public Beta

**Target:** make outside testing possible without ambiguity.

Required evidence:

- Documented build/install procedure.
- Supported kernel matrix.
- Issue templates.
- Panic report templates.
- Automated smoke/stress scripts.
- Known-good and known-bad kernel versions.
- Tagged release notes.

## V6 Production-Value Candidate

**Target:** production-value engineering structure, not a production guarantee.

Required evidence:

- Supported kernel matrix.
- Clean build.
- Clean unmount and unload.
- Crash consistency tests.
- Power-loss tests.
- `fsck` / recovery story.
- Security review.
- No critical temporary stubs.
- Documented limits.
- Reproducible CI.
- Known safe and unsafe workloads.
