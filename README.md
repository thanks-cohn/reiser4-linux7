# reiser4-linux7

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

