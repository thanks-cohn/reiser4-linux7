# Reiser4 Modernization Progress Report
## 2026-05-29

### Executive Summary

Reiser4 now builds, loads, formats, mounts, creates files, writes files, reads files, and reaches deep teardown paths on Linux 6.8.

The remaining blocker is an inode eviction failure during unmount involving inode 65536.

Current evidence suggests a metadata inode survives teardown with a remaining page/folio attached, preventing successful inode destruction.

This is no longer a broad modernization problem. It is now a localized runtime debugging problem.

---

## Confirmed Working

### Build and Module Loading

- Reiser4 builds as an out-of-tree kernel module on Ubuntu 24.04.
- Module loads successfully into Linux 6.8.
- Module initialization completes.

### Filesystem Operations

Successfully demonstrated:

- mkfs.reiser4
- loop device setup
- mount
- file creation
- file write
- file read
- sync operations
- transaction activity
- flush activity

### Runtime Progress

Filesystem execution now reaches:

- inode eviction
- page invalidation
- writeback completion
- truncate paths
- teardown logic

---

## Current Failure

Unmount currently terminates with a segmentation fault.

Diagnostic traces consistently show:

BUMRUSH26_WRITEBACK_DONE ino=65536 nrpages=2
BUMRUSH26_TRUNCATE_PAGES ino=65536 nrpages=1
BUMRUSH26_INVALIDATE_MAPPING ino=65536 nrpages=1
BUMRUSH26_FOLIO_ERR ino=65536 err=-2 nrpages=1
BUMRUSH26_EVICT refusing clear_inode ino=65536 nrpages=1

A normal inode (42) evicts successfully.

The failure is consistently associated with inode 65536.

---

## Important Observations

1. Writeback completes successfully.

2. Truncate reduces page count from 2 to 1.

3. One page survives teardown.

4. release_folio diagnostics never appear.

5. invalidatepage diagnostics do not appear.

---

## Current Hypothesis

The remaining failure appears to be a Linux 6.x folio-era teardown mismatch involving internal Reiser4 metadata objects.

Most likely candidates:

- Internal metadata inode uses an unexpected address_space_operations table.
- invalidate_folio and/or release_folio callbacks are not executing.
- A page-to-jnode relationship survives teardown due to a folio transition issue.

---

## Current Status

Builds:        YES
Loads:         YES
Formats:       YES
Mounts:        YES
Creates files: YES
Writes files:  YES
Reads files:   YES
Unmounts:      NO

Remaining blocker:
inode 65536 eviction failure.
