# Long Name Roadmap

This roadmap restores the Reiser4-NX large filename dream as a staged safety
program. It does not claim native large-name support today.

| Stage | Definition | Exit evidence |
| --- | --- | --- |
| V0-LN | Normal Linux filename boundary behavior is tested and documented. | Boundary probes include expected safe success/failure behavior around 255-byte components and long paths. |
| V1-LN | Current Reiser4-NX observed filename limits are recorded from tests. | `tests/large_filename_probe.sh` artifacts record the exact maximum observed successful component length and dmesg status. |
| V2-LN | Codebase name-limit audit is complete. | `tools/reiser4_name_limit_audit.sh` results are reviewed and summarized in `docs/status/LONG_NAME_AUDIT.md`. |
| V3-LN | True-name metadata design is documented. | Design covers storage, indexing, lookup tooling, fsck/recovery, rename semantics, and collision handling. |
| V4-LN | Prototype userland true-name manifest tool exists. | Tool can emit safe names plus a manifest containing full true names and integrity metadata. |
| V5-LN | True names survive export/import workflows. | Export to compatibility filesystems and import back to Reiser4-NX restores true names. |
| V6-LN | True names survive backup/restore/recovery drills. | Backup, restore, remount, fsck/recovery, and damaged-image drills preserve or report true-name state. |
| V7-LN | Native large POSIX name feasibility is evaluated honestly. | Kernel/VFS/userspace constraints are documented with go/no-go criteria and test evidence. |
| V8-LN | Native experimental mode exists only if safe. | Any implementation is gated behind an explicit experimental mount option and guarded by tests. |
| V9-LN | 4000-character names become a tested Reiser4-NX feature path. | 4000-character true names, and native names if ever enabled, have repeatable proof artifacts. |
