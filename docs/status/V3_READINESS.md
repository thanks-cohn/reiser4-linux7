# V3 Readiness Tracker

This tracker intentionally does **not** claim V3. V3 is reached only when `tests/prove_reiser4_v3.sh` passes and the saved `dmesg` artifact is clean after human review.

## Current Blockers

1. `mkdir` correctness: observed `EPERM` remains a blocker until the exact branch is proven and fixed.
2. Clean unmount: eviction/page teardown must complete without unsafe `clear_inode()` bypasses, warnings, hangs, or leaked state.
3. Remount verification: data must survive unmount/remount and be revalidated by the proof script.
4. Module unload: `rmmod reiser4` must succeed without lingering refs, `entd`, or `ktxnmgrd` teardown problems.
5. Known unsafe ctail path: `assign_conversion_mode()` / `convert_ctail()` NULL dereference remains outside any supported personal-use path.

## Required Scripts

| Purpose | Script | Required for V3? | Status |
| --- | --- | --- | --- |
| V1 lifecycle | `scripts/reiser4-v1-smoke.sh` | Yes | Exists; used by V3 proof wrapper. |
| Focused mkdir regression | `scripts/reiser4-v3-mkdir-regression.sh` | Yes | Exists; strengthened with rename/delete/remount/`dmesg` scan. |
| V3 proof wrapper | `tests/prove_reiser4_v3.sh` | Yes | Exists; this is the only V3 gate. |
| Failure bundle | `tools/reiser4_failure_bundle.sh` | Diagnostic | Exists; captures environment, logs, mount, loop, and module state. |
| Environment report | `tools/reiser4_env_report.sh` | Diagnostic | Exists; records kernel/compiler/reiser4progs/git/runtime state. |
| Danger scan | `tools/reiser4_danger_scan.sh` | Diagnostic | Exists; tracks risky markers and temporary stubs. |

## Last Observed Failure

Latest local proof-run attempt documented in this workspace:

```text
tests/smoke_reiser4_v1.sh
REISER4_V1: kernel build directory not found: /lib/modules/6.12.47/build
REISER4_V1: FAIL: build failed and ./reiser4.ko does not exist
```

This workspace can syntax-check scripts, but cannot currently complete the runtime filesystem gates without matching kernel build headers or a compatible prebuilt `reiser4.ko`.

## Exact Version Fields

| Field | Current value | How to update |
| --- | --- | --- |
| Kernel version | Unknown for a successful V3 run. | Paste exact `uname -a` from `tools/reiser4_env_report.sh`. |
| reiser4progs version | Unknown for a successful V3 run. | Paste exact `mkfs.reiser4` and `fsck.reiser4` versions from `tools/reiser4_env_report.sh`. |
| Git commit | Unknown for a successful V3 run. | Paste `git rev-parse HEAD` from the proof host. |

## V3 Checklist

| Requirement | Current state | Evidence |
| --- | --- | --- |
| mkdir passes | Not proven | `scripts/reiser4-v3-mkdir-regression.sh` must pass. |
| clean unmount passes | Not proven | V3 gate must unmount cleanly and leave no dangerous `dmesg`. |
| remount passes | Not proven | V3 gate must remount and verify files after unmount. |
| rmmod passes | Not proven | V3 gate must unload the module cleanly when it loaded it. |
| stress passes | Not proven | V3 gate must finish many-small-files and rename/delete stress. |
| dmesg is clean | Not proven | V3 gate must scan logs and reviewer must inspect saved artifact. |

## Still Unsafe

- Valuable data.
- Unsupported kernels or unrecorded kernel builds.
- Real disks not explicitly marked sacrificial.
- Workloads that hit the known `ctail` / `assign_conversion_mode()` NULL-deref path.
- Any run with `BUG`, `Oops`, `panic`, `null pointer`, `WARNING`, or `use-after-free` in the relevant `dmesg` window.
- Any run that cannot cleanly unmount, remount, and unload the module.

## Current Instrumentation

`plugin/inode_ops.c` emits `BUMRUSH26_MKDIR_*` tags around `reiser4_mkdir_common()` and the child creation path so the next kernel-capable host can identify the exact `EPERM` branch. `super_ops.c::reiser4_evict_inode()` emits inode, mapping, page/folio, dirty, writeback, private, and refcount state to diagnose clean-unmount failure.
