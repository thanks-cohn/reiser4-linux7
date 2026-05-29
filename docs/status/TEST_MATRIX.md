# Reiser4-Linux7 Test Matrix

Use this table for every meaningful proof run. Unknown values must remain explicit; do not infer them after the fact.

| Date | Git commit | Kernel version | Compiler | reiser4progs version | Storage | Loopback result | Real disk result | mkdir | rename | delete | sync | unmount | remount | rmmod | stress | fsck | Log/artifact |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-05-29 | TBD | Host lacks matching build headers in this workspace | TBD | TBD | Loopback | Blocked before proof | Not run | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | TBD |

## Required Fields

- **Kernel version:** exact `uname -a` output, not only major/minor.
- **Compiler:** exact first line of `gcc --version` or the compiler actually used by Kbuild.
- **reiser4progs version:** exact `mkfs.reiser4` and `fsck.reiser4` versions if available.
- **Loopback result:** pass/fail/blocked plus gate script name.
- **Real disk result:** pass/fail/not-run and device class; never hide destructive-device assumptions.
- **Operation columns:** pass/fail/blocked/not-run for `mkdir`, `rename`, `delete`, `sync`, `unmount`, `remount`, `rmmod`, `stress`, and `fsck`.
- **Log/artifact:** path under `artifacts/` whenever the run generated logs.
