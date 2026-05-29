# V3 Readiness Status

V3 is **not reached** until `tests/prove_reiser4_v3.sh` passes on the stated target environment and the run evidence shows no supported-path kernel BUG, Oops, panic, warning explosion, NULL dereference, or use-after-free.

## Target Environment

- Kernel target: Linux `6.12.47` for the current workspace host; historical bring-up notes also reference Ubuntu 24.04 / Linux 6.8 and Linux 7.x compatibility work.
- Reiser4 userspace target: `mkfs.reiser4` and reiser4progs must be installed and recorded by the proof runner when available. The current workspace does not have `mkfs.reiser4` in `PATH`, so the exact reiser4progs version remains **unknown / to be recorded on the test host**.

## Current Blockers

1. `mkdir` returns `EPERM` on the current V1 path until proven fixed by `tests/smoke_reiser4_v1.sh`.
2. `ctail` / `assign_conversion_mode` NULL dereference exists on another path and must not be part of the supported V3 path until fixed.
3. Inode `65536` eviction / teardown bug remains unresolved until clean unmount evidence is captured.
4. Clean unmount and module unload instability remains unresolved until V1/V2/V3 proof scripts complete with `rmmod` success and clean `dmesg` checks.

## Required Passing Scripts

- `tests/smoke_reiser4_v1.sh`
- `tests/stress_reiser4_v2.sh 1000`
- `tests/prove_reiser4_v3.sh`

## Known Unsafe Uses

- Daily-driver use.
- Any unbacked or valuable data.
- Production use.
- Power-loss or crash-consistency claims.
- Multi-user or security-sensitive deployments.
- Disk-device testing outside an explicitly sacrificial block device.
- Workloads that hit the known `ctail` / `assign_conversion_mode` NULL-deref path.
- Workloads that require clean teardown before the unmount / `rmmod` blocker is proven fixed.

## Known Safe Experimental Uses

Until V3 passes, the only intended safe path is controlled loopback testing on disposable images using the proof scripts in `tests/`.

After V3 passes, the intended experimental path is still limited to disposable loopback images and explicitly sacrificial block devices, with backups and no valuable data.

## Sacrificial Disk Path Requirement

Before any non-loopback V3 experiment, document all of the following in the test log:

- Exact block device path.
- Confirmation that the device contains no valuable data.
- Kernel version.
- Reiser4progs version.
- Git commit under test.
- Full command transcript.
- `dmesg` scan result after unmount and module unload.

## Last Observed Failure

The mission statement identifies the current functional blockers as `mkdir` returning `EPERM`, a `ctail` / `assign_conversion_mode` NULL dereference on another path, inode `65536` eviction / teardown failure, and clean unmount / module unload instability.

Latest local proof-run attempt in this workspace:

```text
tests/smoke_reiser4_v1.sh
REISER4_V1: kernel build directory not found: /lib/modules/6.12.47/build
REISER4_V1: FAIL: build failed and ./reiser4.ko does not exist
```

That means this workspace can syntax-check the scripts, but cannot yet run the V1 gate because the host lacks matching kernel build headers and no prebuilt `reiser4.ko` is present.

## mkdir EPERM Investigation Status

`plugin/dir_plugin_common.c::estimate_init()` has been inspected and currently returns the computed `res` reservation. No behavior-changing reservation patch was made in this pass because the suspected `return 0` is not present in the current code.

The current patch adds `BUMRUSH26_MKDIR_*` printk instrumentation so the next kernel-capable test host can identify whether `EPERM` comes from a missing file-plugin `create_object`, a missing directory-plugin `init`, reservation failure after the mkdir estimate, or another return path.

## Next Required Fix

Run `tests/smoke_reiser4_v1.sh` on a host with matching kernel build headers, `mkfs.reiser4`, and either a buildable or prebuilt `reiser4.ko`. Use the `BUMRUSH26_MKDIR_*` dmesg output to patch only the confirmed `mkdir` `EPERM` return path.
