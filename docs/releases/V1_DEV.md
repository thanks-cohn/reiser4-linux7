# Reiser4-NX v1 Developer Release

## Status

Reiser4-NX v1-dev is a developer release for Ubuntu 24.04 / Linux 6.8.

It is not production-ready.

## Confirmed Working

- Builds as an out-of-tree kernel module.
- Loads into the running kernel.
- Formats a loopback image with mkfs.reiser4.
- Mounts the formatted image.
- Creates files.
- Writes files.
- Reads files.
- Reaches sync, transaction, flush, and inode teardown paths.

## Known Blocker

Clean unmount is not yet working.

Current failure:

    inode 65536 survives eviction with nrpages=1

Observed trace:

    BUMRUSH26_WRITEBACK_DONE ino=65536 nrpages=2
    BUMRUSH26_TRUNCATE_PAGES ino=65536 nrpages=1
    BUMRUSH26_INVALIDATE_MAPPING ino=65536 nrpages=1
    BUMRUSH26_FOLIO_ERR ino=65536 err=-2 nrpages=1
    BUMRUSH26_EVICT refusing clear_inode ino=65536 nrpages=1

## v1-dev Definition

v1-dev means the repository has a reproducible modern-kernel bring-up path:

    build -> load -> mkfs -> mount -> write -> read

with the remaining unmount blocker documented and reproducible.

## Next Release Targets

- v1.1: identify the exact role of inode 65536.
- v2: clean unmount.
- v3: repeated mount/write/read/unmount smoke loops pass.
