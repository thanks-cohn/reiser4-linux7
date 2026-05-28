# Latent Bug

## Summary

During Reiser4-NX bring-up on Ubuntu 24.04 / Linux 6.8, directory creation failed while ordinary file creation, file writes, file reads, mounting, and stat operations were already working.

The failure presented as:

```text
mkdir: cannot create directory: Operation not permitted
```

This was notable because the filesystem was otherwise far enough along to create regular files and persist simple data. That narrowed the failure to the directory creation path rather than general VFS registration, module loading, mounting, or basic item insertion.

## Area Investigated

The failing path led into:

```text
plugin/inode_ops.c
plugin/dir_plugin_common.c
```

Specifically:

```c
reiser4_mkdir_common()
create_vfs_object()
reiser4_dir_init_common()
create_dot_dotdot()
```

Directory creation differs from regular file creation because it must create and account for:

```text
.
..
directory entry insertion
link count updates
stat-data updates
transaction reservation
```

## Suspicious Function

The key issue was found in:

```c
plugin/dir_plugin_common.c
```

Inside:

```c
static reiser4_block_nr estimate_init(struct inode *parent,
                                      struct inode *object)
```

The function computed a reservation estimate:

```c
res += inode_dir_plugin(object)->estimate.add_entry(object);
res += inode_file_plugin(object)->estimate.update(object);
res += inode_dir_plugin(object)->estimate.add_entry(object);
res += inode_file_plugin(parent)->estimate.update(parent);
```

But then returned:

```c
return 0;
```

instead of:

```c
return res;
```

## Why This Matters

That means directory initialization was calculating the required transaction reservation and then discarding it.

The immediate implication is that `mkdir` could enter the directory initialization path without reserving space for the operations it was about to perform.

Those operations include adding `.` and `..`, updating link counts, and updating stat-data. Returning zero here is therefore highly suspicious and may explain why ordinary file creation worked while directory creation failed.

## Patch

The current patch changes:

```c
return 0;
```

to:

```c
return res;
```

in `estimate_init()`.

## Impact

This may be a latent logic bug rather than a Linux 6.8 compatibility issue alone.

It is especially interesting because the function already contained the correct reservation calculation. The bug was not that the estimate was missing. The estimate existed, accumulated into `res`, and was simply not returned.

That makes the issue easy to overlook during code review because the body of the function appears intentional until the final line is inspected closely.

## Status

At the time this note was written:

```text
module build: works
module load: works
mkfs: works
mount: works
stat root: works
file create: works
file write/read: works
mkdir: previously failed with EPERM
estimate_init(): patched to return computed reservation
```

The next validation step is to rebuild, reload the module, and rerun the alpha smoke test to determine whether `mkdir` progresses further or passes.

## Implication

If this patch fixes or advances directory creation, it indicates that part of the Reiser4 recovery effort is not only adapting to modern Linux APIs, but also exposing older assumptions and dormant bugs that may have remained hidden or under-tested.

That is important for the project.

It means the modernization effort is not merely cosmetic. It is beginning to clarify old behavior, tighten correctness, and turn a fragile historical codebase into something that can be tested, explained, and improved under modern conditions.
