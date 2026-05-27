# Linux 7 Porting Status

## Current Status

The filesystem core now compiles deep into Linux 7.x kernel internals.

Completed compatibility stages include:

- folio/page cache transition
- bio allocation API adaptation
- page error compatibility
- spinlock compatibility
- congestion compatibility
- dirty-page compatibility
- initial VFS adaptation

## Current Blockers

### Modern filesystem registration API
The legacy:

- `.mount`
- `mount_bdev`
- legacy `file_system_type`

must migrate toward:

- `fs_context`
- `init_fs_context`
- modern mount plumbing

### Superblock operation drift
Removed/changed interfaces:

- `.remount_fs`
- `.writeback_inodes`
- `wb_writeback_work`

### Writeback architecture changes
Linux 7.x removed or reworked:

- `generic_writeback_sb_inodes`
- `writeback_skip_sb_inodes`

requiring architectural adaptation rather than direct symbol replacement.

## Interpretation

This is substantial progress.

The kernel is now compiling nearly the entire lower filesystem engine before failing at final VFS registration and modern writeback interfaces.

The project has transitioned from:
"compile error whack-a-mole"

into:

"a true modern kernel filesystem port."

