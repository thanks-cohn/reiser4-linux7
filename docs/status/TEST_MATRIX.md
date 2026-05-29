# Reiser4-Linux7 Test Matrix

Use this table for every meaningful proof run. Unknown values must remain explicit; do not infer them after the fact.

| Date | Git commit | Kernel version | Compiler | reiser4progs version | Storage | Loopback result | Real disk result | mkdir | rename | delete | sync | unmount | remount | rmmod | stress | fsck | Large filename probe | Max observed successful component length | Long-name dmesg status | True-name support status | Log/artifact |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-05-29 | TBD | Host lacks matching build headers in this workspace | TBD | mkfs.reiser4 not found in this workspace | Loopback | Blocked before proof | Not run | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked: `mkfs.reiser4` not found | Unknown | Not run; probe blocked before mount | Not implemented; design only | `artifacts/large-filename-probe-20260529T133958Z/` |

## Required Fields

- **Kernel version:** exact `uname -a` output, not only major/minor.
- **Compiler:** exact first line of `gcc --version` or the compiler actually used by Kbuild.
- **reiser4progs version:** exact `mkfs.reiser4` and `fsck.reiser4` versions if available.
- **Loopback result:** pass/fail/blocked plus gate script name.
- **Real disk result:** pass/fail/not-run and device class; never hide destructive-device assumptions.
- **Operation columns:** pass/fail/blocked/not-run for `mkdir`, `rename`, `delete`, `sync`, `unmount`, `remount`, `rmmod`, `stress`, and `fsck`.
- **Large filename probe:** pass/fail/blocked/not-run plus the `tests/large_filename_probe.sh` artifact path when available.
- **Max observed successful component length:** exact maximum byte length observed by the large filename probe; use `Unknown` unless the probe actually ran.
- **Long-name dmesg status:** clean/dangerous-pattern-detected/blocked/not-run, based on the probe dmesg scan.
- **True-name support status:** not-implemented/design-only/prototype/pass/fail; do not claim true-name support until export/import/recovery evidence exists.
- **Log/artifact:** path under `artifacts/` whenever the run generated logs.

## Long-Name Evidence Requirements

Long-name rows must never infer support from doctrine or design documents. A valid
entry needs a `tests/large_filename_probe.sh` artifact containing attempted
component lengths, success/failure for each length, remount verification for each
successful name, and dmesg scan status. True-name support remains
`Not implemented` until manifest tooling and recovery tests exist.

## Smoke Suite Rows

| Smoke test | Scope | Required clean preconditions | PASS breadcrumb(s) | FAIL breadcrumb(s) | Artifact pattern | Current expected result |
| --- | --- | --- | --- | --- | --- | --- |
| Build module | Kbuild clean/modules and `reiser4.ko` artifact health. | Matching `/lib/modules/$(uname -r)/build` headers. | `SMOKE_BUILD_PASS` | `SMOKE_BUILD_FAIL stage=<stage>` | `artifacts/smoke_build_module-<timestamp>/` | Should pass on a host with matching kernel headers. |
| Module lifecycle | `insmod`, `lsmod`, `/proc/filesystems`, `rmmod`; no mount. | `reiser4` not preloaded/stuck. | `SMOKE_MODULE_INSMOD_PASS`, `SMOKE_MODULE_PROCFS_PASS`, `SMOKE_MODULE_RMMOD_PASS` | `SMOKE_PREFLIGHT_FAIL module_preloaded=1`, `SMOKE_INSMOD_FAIL`, `SMOKE_RMMOD_FAIL` | `artifacts/smoke_module_lifecycle-<timestamp>/` | Should pass only on a clean boot/clean module state. |
| mkfs mount unmount | `mkfs.reiser4`, loop mount, root stat, unmount, rmmod; no mutation. | Clean module state, `mkfs.reiser4` in `PATH`, root/sudo. | `SMOKE_MKFS_PASS`, `SMOKE_MOUNT_PASS`, `SMOKE_ROOT_STAT_PASS`, `SMOKE_UNMOUNT_PASS`, `SMOKE_RMMOD_PASS` | `SMOKE_MKFS_FAIL`, `SMOKE_MOUNT_FAIL`, `SMOKE_ROOT_STAT_FAIL`, `SMOKE_UNMOUNT_FAIL`, `SMOKE_RMMOD_FAIL` | `artifacts/smoke_mkfs_mount_unmount-<timestamp>/` | mkfs/mount/root stat likely pass. |
| Regular file rw | Root-level regular file create/write/read/sync/remount verify; no mkdir. | Build, lifecycle, and mount/unmount pass. | `SMOKE_FILE_CREATE_PASS`, `SMOKE_FILE_WRITE_PASS`, `SMOKE_FILE_READ_PASS`, `SMOKE_FILE_REMOUNT_VERIFY_PASS` | `SMOKE_FILE_CREATE_FAIL`, `SMOKE_FILE_WRITE_FAIL`, `SMOKE_FILE_READ_FAIL`, remount verify failure | `artifacts/smoke_regular_file_rw-<timestamp>/` | May pass depending current code. |
| mkdir only | Isolated mkdir microscope. | Build, lifecycle, and mount pass. | `SMOKE_MKDIR_PASS` | `SMOKE_MKDIR_FAIL error="..."` | `artifacts/smoke_mkdir_only-<timestamp>/` | Currently expected to fail with `EPERM`. |
| Teardown after failure | Trigger known mkdir failure and verify cleanup resilience. | Clean module state and reproducible mkdir failure. | `SMOKE_EXPECTED_MKDIR_FAIL`, `SMOKE_TEARDOWN_AFTER_FAIL_PASS` | `SMOKE_TEARDOWN_AFTER_FAIL_FAIL module_stuck=1 ktxnmgrd_alive=1 loop_deleted=1` or equivalent flags | `artifacts/smoke_teardown_after_failure-<timestamp>/` | Currently expected to expose stuck module/ktxnmgrd risk. |
| Full V1 smoke | End-to-end staged V1 path with mkdir and teardown breadcrumbs. | All foundational tests pass and mkdir/teardown are clean. | `SMOKE_MKFS_PASS` through `SMOKE_VERIFY_AFTER_REMOUNT_PASS` and `SMOKE_RMMOD_PASS` | Stage-specific `SMOKE_*_FAIL`, especially `SMOKE_MKDIR_FAIL` and teardown failures | `artifacts/smoke_reiser4_v1-<timestamp>/` | Not passed until mkdir and teardown are clean. |
