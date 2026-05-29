# Reiser4 Revival Milestone
## 2026-05-29 04:44 AM Mexico City time

At approximately **4:44 AM Mexico City time**, this Reiser4 modernization effort reached a meaningful revival milestone.

The project now demonstrates that Reiser4 can be brought far enough forward on Ubuntu 24.04 / Linux 6.8 to build as an out-of-tree kernel module and reach real runtime behavior.

## Confirmed Progress

- Reiser4 source builds again as a modern out-of-tree kernel module.
- `reiser4.ko` is produced successfully.
- `mkfs.reiser4` creates a filesystem image.
- The module has previously loaded on Linux 6.8.
- The filesystem has previously mounted on loopback media.
- Regular file creation, write, and read behavior have been observed.
- Transaction and flush machinery is reached.
- The `convert_ctail()` bypass was proven to hide a real crash.
- The crash has been localized to `assign_conversion_mode()` in `plugin/item/ctail.c`.
- The earlier inode eviction failure involving inode `65536` remains a major teardown blocker.
- Kbuild out-of-tree module behavior was corrected by switching the module build path to `obj-m`.

## Current Frontier

The current primary blocker is no longer broad modernization.

It is localized runtime correctness:

1. `assign_conversion_mode()` / `convert_ctail()` NULL dereference.
2. Directory creation failure.
3. Inode `65536` lingering page/folio during eviction.
4. Clean unmount and module unload stability.

## Significance

This is no longer merely a compile resurrection.

This is a live filesystem debugging effort.

Reiser4 is now far enough forward that the remaining work can be traced through concrete runtime failures instead of speculation.

That distinction matters.

A filesystem that reaches real I/O, transaction activity, and reproducible kernel traces is no longer dead code.

It is wounded infrastructure.

And wounded infrastructure can be healed.
