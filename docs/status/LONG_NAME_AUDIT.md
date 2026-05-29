# Long Name Audit

## Purpose

This audit tracks the code and documentation locations that may affect Reiser4-NX
filename component limits, whole-path limits, VFS-facing behavior, directory
item handling, user-visible errors, and future true-name support.

The audit is a safety prerequisite. It must identify hard limits, soft limits,
implicit assumptions, and unknowns before any native large POSIX name experiment
is attempted.

## Audit Command

```sh
tools/reiser4_name_limit_audit.sh
```

The command searches for `NAME_MAX`, `PATH_MAX`, `QSTR`, `qstr`, `dentry`,
`d_name`, `name.len`, `namelen`, `name_len`, `strlen`, `strnlen`, `memcpy`,
`strncpy`, `ENAMETOOLONG`, `EOVERFLOW`, `filename`, `lookup`, `mkdir`, `rename`,
`unlink`, `link`, `dirent`, and `directory item`, while excluding build outputs,
`.git`, and `artifacts/`.

## Current Run Summary

Status: seeded and run once for initial triage. The result set is broad and is
not yet a completed semantic audit. The initial run produced 1966 matching
lines in `artifacts/name-limit-audit-initial.txt`; the highest-count files were
`plugin/inode_ops_rename.c`, `plugin/inode_ops.c`,
`plugin/dir_plugin_common.c`, `safe_link.c`, and `txnmgr.c`.

Initial command used:

```sh
tools/reiser4_name_limit_audit.sh > artifacts/name-limit-audit-initial.txt
```

## Findings Table

| Path | Symbol/check | Current meaning | Risk | Next action |
| --- | --- | --- | --- | --- |
| `plugin/dir_plugin_common.c` | `d_name.len`, `ENAMETOOLONG`, `is_name_acceptable_common` | Common directory checks compare dentry name length against `reiser4_max_filename_len()`. | High because this appears to be a central create/lookup boundary. | Review all callers and confirm consistent behavior for lookup, create, mkdir, link, unlink, rename, and readdir. |
| `inode.c`, `inode.h` | `reiser4_max_filename_len` | Central helper returns the directory item plugin maximum name length or 255 as a fallback. | High because it is the apparent source of Reiser4-specific component limits. | Classify actual plugin maximums and verify whether VFS rejects larger names before this helper is reached. |
| `plugin/item/cde.c`, `plugin/item/sde.c`, `plugin/item/item.h` | `max_name_len`, `max_name_len_cde`, `max_name_len_de` | Directory item plugins derive maximum name length from node maximum item size and directory-entry format overhead. | High because these values are related to the historical large-name ambition and on-disk packing constraints. | Audit exact computed values for supported node formats without changing layout. |
| `plugin/inode_ops.c`, `plugin/file_plugin_common.c` | `ENAMETOOLONG`, `dentry->d_name.len` | Operation paths return length errors for unacceptable names or oversized item data. | High if mkdir/create/rename paths diverge in limit enforcement. | Compare create, mkdir, link, unlink, and rename error paths against probe results. |
| `super_ops.c` | `f_namelen` | `statfs` reports `reiser4_max_filename_len()` for the root directory. | Medium because userspace may infer support from this value even if VFS/tooling cannot handle it. | Compare reported `f_namelen` with actual probe successes and userspace behavior. |
| `export_ops.c`, `fsdata.c`, `super.h` | `dentry`, `dentry_operations`, `dentry_fsdata` | Dentry lifecycle and export paths are heavily represented in audit results. | Medium to high for native large names; low for documentation-only true-name planning. | Review only after boundary semantics are understood. |
| `plugin/`, `lib/`, root source files | `strlen`, `strnlen`, `memcpy`, `strncpy` | Broad string and memory-copy matches include many unrelated uses plus possible name-copy assumptions. | Medium until triaged. | Filter to name-bearing structures and destination buffers. |
| `tests/`, `tools/`, `docs/status/TEST_MATRIX.md` | `filename`, `mkdir`, `rename`, `unlink`, `link` | Existing proof and stress scaffolding already covers normal operations. | Medium if long-name behavior is not recorded alongside normal operation results. | Add long-name probe artifacts to the test matrix after privileged runs. |
| `docs/design/LARGE_FILENAME_SUPPORT.md`, `docs/status/LONG_NAME_ROADMAP.md` | true-name design terms | Documentation-only strategy for future compatibility-safe true names. | Low for runtime behavior; high for scope control if treated as implemented. | Keep marked as future design until tests and tools exist. |

## Suspected Hard Limits

- The normal Linux filename component boundary around 255 bytes remains the
  expected compatibility boundary until probe evidence says otherwise.
- VFS/dentry/`qstr` validation may reject oversized components before Reiser4-NX
  filesystem methods can safely interpret them.
- Existing Reiser4-NX code contains explicit `ENAMETOOLONG` handling in
  directory and inode operation paths that must be understood before any
  experiment.
- `reiser4_max_filename_len()` is the apparent Reiser4-specific component-limit
  helper; directory item plugins compute larger theoretical maxima from node
  item size, while the fallback is 255.

## Suspected Soft Limits

- Userspace tools may fail, truncate, quote incorrectly, or skip files even if a
  mounted filesystem accepts larger components.
- Whole-path length assumptions may fail independently from component length.
- Documentation, tests, and backup workflows currently do not prove true-name
  export/import or recovery behavior.

## Unknowns

- Exact current maximum successful Reiser4-NX filename component length on a
  mounted loopback filesystem.
- Whether any oversized attempt reaches Reiser4-NX code or is rejected earlier
  by Linux pathname handling.
- Whether directory item layout contains latent room for large names without
  unsafe side effects.
- Whether fsck/recovery tools preserve, reject, or mishandle large-name edge
  cases.
- Best durable storage location and index model for future true names.

## Next Steps

1. Run `tests/large_filename_probe.sh` in a privileged environment with
   `mkfs.reiser4` and a loadable Reiser4 module.
2. Attach the probe artifact path and observed maximum component length to
   `docs/status/TEST_MATRIX.md`.
3. Review the audit hits operation by operation and update the findings table
   with concrete file/function-level conclusions.
4. Draft the V3-LN true-name metadata design before any implementation.
5. Do not alter lookup, mkdir, rename, dentry handling, `qstr` handling,
   VFS-facing validation, directory item layout, or on-disk format until the
   audit and probe evidence justify a safe next step.
