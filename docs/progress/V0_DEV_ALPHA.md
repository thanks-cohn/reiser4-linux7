# Reiser4-NX v0 Developer Alpha

## Status

This repository has reached v0 developer-alpha status for Ubuntu 24.04 / Linux 6.8.

## Confirmed Working

- Builds as an out-of-tree kernel module.
- Loads into the running kernel.
- Formats a loopback image with mkfs.reiser4.
- Mounts the formatted image.
- Creates files.
- Writes files.
- Reads files.
- Reaches transaction, flush, sync, and inode teardown paths.

## Known Blocker

Unmount currently fails during inode eviction.

Current failing inode:

    ino=65536

Observed pattern:

    BUMRUSH26_WRITEBACK_DONE ino=65536 nrpages=2
    BUMRUSH26_TRUNCATE_PAGES ino=65536 nrpages=1
    BUMRUSH26_INVALIDATE_MAPPING ino=65536 nrpages=1
    BUMRUSH26_FOLIO_ERR ino=65536 err=-2 nrpages=1
    BUMRUSH26_EVICT refusing clear_inode ino=65536 nrpages=1

Normal inode eviction has been observed to succeed for inode 42.

## v0 Definition

This is not production-ready.

This v0 means:

    build -> load -> mkfs -> mount -> write -> read

works on Linux 6.8, with a known and documented unmount eviction blocker.

## Next Target

v0.1 should resolve the inode 65536 eviction/pagecache teardown failure and allow clean unmount.
