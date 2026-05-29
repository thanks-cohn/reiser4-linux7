
# Reiser4-NX Modernization Status

## Current State (2026-05-29)

Reiser4 is no longer a compile-only resurrection project.

Current achievements:

- Builds successfully as an out-of-tree kernel module on Ubuntu 24.04 / Linux 6.8.
- Produces a working `reiser4.ko`.
- Formats loopback images via `mkfs.reiser4`.
- Successfully loads into the kernel.
- Successfully mounts.
- Successfully creates files.
- Successfully writes files.
- Successfully reads files.
- Successfully reaches transaction paths.
- Successfully reaches flush paths.

The remaining failures are no longer broad modernization issues.

The project has advanced into runtime debugging.

Current active frontiers:

1. `convert_ctail()` / `assign_conversion_mode()` NULL dereference.
2. Directory creation path correctness.
3. Inode 65536 eviction and teardown behavior.
4. Clean unmount and module unload stability.

A filesystem that reaches real I/O, real transactions, real flush activity, and reproducible kernel traces is no longer dead code.

It is active engineering.

---

**Milestone**

At approximately 4:44 AM Mexico City time on 2026-05-29, the project crossed from broad porting work into localized runtime debugging.


# Reiser4-NX Modernization Progress

## Current Status

Active Reiser4 modernization effort targeting Ubuntu 24.04 / Linux 6.8.

Recent progress:

- Reiser4 builds as a kernel module.
- Module loads into kernel space.
- Loopback images can be formatted.
- Filesystem can mount.
- Root stat works.
- Regular file creation works.
- File write/read works.
- Transaction and flush paths are reached.
- Directory creation failure was narrowed.
- Latent mkdir reservation bug found in plugin/dir_plugin_common.c.
- Generated kernel/build artifacts removed from Git tracking.
- Remaining major failure is inode eviction / teardown during unmount.

## What Changed From the Original Codebase

- Code now reaches real runtime testing.
- Build junk is ignored: *.o, *.cmd, *.d, Module.symvers, modules.order, *.img.
- mkdir failure was narrowed to directory creation path.
- estimate_init() was found calculating reservation cost into res but returning 0.
- Modern Linux teardown exposed inode eviction failure before clear_inode().
- Shrinker path likely needs modernization with shrinker_alloc().

## Current Known Failure

Unmount currently reaches clear_inode through reiser4_evict_inode and trips a kernel BUG.

## Next Work

- Validate whether estimate_init() fix advances or fixes mkdir.
- Instrument reiser4_evict_inode() before clear_inode().
- Print inode state, dirty flags, private pointer, mapping pointer, refcount, and link count.
- Modernize shrinker registration.
- Keep documenting changed failure modes in docs/status/.

See docs/status/LATENT_BUG.md and docs/status/EVICTION_TRACE_NOTES.md.

---

# reiser4-linux7


## Recent Changes — Notes From The Frontier

Reiser4 now builds and loads successfully on Linux 7.x kernels again.

This repository has entered a new phase focused on long-term survivability, modern kernel compatibility, and durable filesystem stewardship.

Recent work includes:

- Linux 7.x VFS compatibility restoration
- Modern MM/pagecache compatibility shims
- Folio-transition adaptation layers
- Inode timestamp modernization
- Removal/replacement of obsolete kernel interfaces
- Successful `reiser4.ko` module build and load on Linux 7
- Successful `mkfs.reiser4` filesystem creation on loopback devices
- Initial compatibility membrane groundwork for future portability efforts

This is not yet production-safe.

Current goals are stability, observability, correctness, recoverability, and reducing dependence on unstable internal kernel interfaces over time.

The old Linux world assumed filesystems and kernels would continue evolving together indefinitely. Time proved otherwise.

Many things changed:
- VFS internals shifted
- MM/pagecache evolved
- writeback semantics hardened
- folios replaced old assumptions
- interfaces once considered stable disappeared

Yet the core ideas behind Reiser4 still remain compelling:
small-file efficiency,
modularity,
plugin-oriented architecture,
and filesystem experimentation unafraid of difficult ideas.

The current direction is intentionally conservative in implementation strategy:
- compatibility layers over invasive rewrites
- explicit modernization seams
- reduction of hidden coupling
- clearer subsystem boundaries
- infrastructure that future contributors can actually continue

Boring is good.
Predictable is good.
Survivable is good.

This effort exists not merely to preserve an old filesystem,
but to explore whether durable filesystem architecture can still exist in an era of rapidly shifting internals and increasingly disposable software stacks.

Somewhere between early Linux pragmatism and modern systems reality,
the work continues.



---

## Current Porting State

This branch now builds deep into the Reiser4 kernel module on Linux `7.0.3-zen1-2-zen`.

Completed or started compatibility work:

- Linux 7 compatibility layer
- folio/page-cache transition work
- BIO allocation/reset/op compatibility
- shrinker API compatibility
- inode state compatibility via `inode_state_read`
- dirty-page helper compatibility
- discard/TRIM API update
- initial `fs_context` migration stub
- obsolete writeback daemon path temporarily stubbed

Current frontier:

- `plugin/object.c`
- modern VFS object layer
- folio-native `address_space_operations`
- `mnt_idmap` replacing `user_namespace`
- `.iterate_shared` replacing `.iterate`
- modern splice/read helpers

This branch is not production-ready. Some paths are temporary stubs to push the build frontier forward. Do not use on valuable data.


## Revival Milestone — 2026-05-29

At approximately **4:44 AM Mexico City time**, this repository reached a meaningful Reiser4 revival milestone.

The project now builds `reiser4.ko` as an out-of-tree kernel module on Ubuntu 24.04 / Linux 6.8 and has reached real runtime filesystem behavior: module loading, loopback formatting, mounting, regular file creation, write/read operations, transaction paths, and flush paths.

The current frontier has narrowed to concrete runtime failures:

- `assign_conversion_mode()` / `convert_ctail()` NULL dereference.
- Directory creation failure.
- Inode `65536` eviction / teardown failure.
- Clean unmount and module unload stability.

See `docs/status/REISER4_REVIVAL_2026_05_29.md`.

