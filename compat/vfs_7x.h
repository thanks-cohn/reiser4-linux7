#ifndef REISER4_VFS_7X_H
#define REISER4_VFS_7X_H

#include <linux/fs.h>
#include <linux/mount.h>
#include <linux/namei.h>
#include <linux/pagemap.h>

/*
 * Linux 7.x VFS compatibility layer
 */

/* iterate -> iterate_shared */
#ifndef HAVE_ITERATE_SHARED
#define reiser4_iterate iterate_shared
#endif

/* generic splice helper fallback */
#ifndef filemap_splice_read
#define filemap_splice_read generic_file_splice_read
#endif

/* inode state compatibility */
#ifndef inode_state
#define inode_state(inode, flag) (inode_state_read(inode) & (flag))
#endif

/* dirty page compatibility */
#ifndef __set_page_dirty_nobuffers
#define __set_page_dirty_nobuffers(page) \
    filemap_dirty_folio(page_mapping(page), page_folio(page))
#endif

/* page mapping helper */
#ifndef page_mapping
#define page_mapping(page) ((page)->mapping)
#endif

/* write congestion removed in newer kernels */
#ifndef bdi_write_congested
#define bdi_write_congested(bdi) (0)
#endif

/* page error helpers */
#ifndef SetPageError
#define SetPageError(page) do { } while (0)
#endif

#ifndef ClearPageError
#define ClearPageError(page) do { } while (0)
#endif

#ifndef PageError
#define PageError(page) (0)
#endif

#endif
