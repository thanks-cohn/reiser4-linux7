# Reiser4-NX Eviction Trace Notes

## Summary

During unmount testing on Ubuntu 24.04 / Linux 6.8, Reiser4 successfully:

- built as a module
- loaded into kernel space
- formatted loopback images
- mounted successfully
- created files
- performed read/write operations
- entered transaction and flush paths

The remaining failure occurs during inode eviction and teardown.

Kernel trace:

~text
kernel BUG at fs/inode.c:649!
RIP: clear_inode+0x7f/0x90
Call Trace:
reiser4_evict_inode
~

This strongly suggests Reiser4 is violating modern Linux inode teardown expectations before clear_inode() is reached.

## Additional Signals

Observed warning during module load:

~text
Must use shrinker_alloc() to dynamically allocate the shrinker
~

This indicates Reiser4 still uses an older shrinker registration model incompatible with newer kernel expectations.

## Current Hypothesis

Likely causes before clear_inode():

- dirty inode state remaining
- lingering writeback state
- incomplete page cache invalidation
- private filesystem state not released
- transaction references still attached
- modern VFS teardown ordering mismatch

## Next Diagnostic Step

Instrument reiser4_evict_inode() immediately before clear_inode():

~c
printk(KERN_ERR
    "REISER4_EVICT inode=%lu state=%lx nlink=%u dirty=%d private=%p mapping=%p count=%d\n",
    inode->i_ino,
    inode->i_state,
    inode->i_nlink,
    inode->i_state & I_DIRTY_ALL,
    inode->i_private,
    inode->i_mapping,
    atomic_read(&inode->i_count));
~

Goal:

Identify which inode state survives into eviction under Linux 6.8.

## Broader Implication

This appears to be a latent compatibility bug that likely existed unnoticed for years because older kernels tolerated teardown behavior now considered invalid.

Modern kernels are stricter.

Reiser4 is now reaching codepaths that expose those assumptions directly.
