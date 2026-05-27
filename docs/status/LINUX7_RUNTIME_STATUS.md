# Linux 7 Runtime Status — Reiser4 Resurrection

## Current State

Reiser4 now:

- builds on Linux 7.x
- loads as a kernel module
- mounts successfully
- survives fsck traversal

Current runtime status:

- mount path: operational
- metadata mutation path: unstable
- write path: unstable

## Historic Milestone

Tag:

linux7-first-successful-mount

marks the first successful Linux 7 Reiser4 mount.

## Warning

This filesystem is NOT production safe yet.

Do not store valuable data on it.

Current status should be considered:

experimental runtime resurrection

not:

stable filesystem port

