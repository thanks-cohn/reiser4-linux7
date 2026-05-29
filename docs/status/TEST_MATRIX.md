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
