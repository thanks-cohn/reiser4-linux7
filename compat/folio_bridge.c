#include <linux/fs.h>
#include <linux/pagemap.h>
#include <linux/mm.h>
#include <linux/writeback.h>
#include <linux/buffer_head.h>

/*
 * Transitional Linux 7 folio bridge
 *
 * Minimal ABI bridge while Reiser4 remains page-era internally.
 */

int reiser4_nx_read_folio(struct file *file, struct folio *folio)
{
    return 0;
}

bool reiser4_nx_dirty_folio(struct address_space *mapping,
                            struct folio *folio)
{
    return true;
}

void reiser4_nx_readahead(struct readahead_control *rac)
{
}

int reiser4_nx_write_begin(const struct kiocb *iocb,
                           struct address_space *mapping,
                           loff_t pos,
                           unsigned len,
                           struct folio **foliop,
                           void **fsdata)
{
    return 0;
}

int reiser4_nx_write_end(const struct kiocb *iocb,
                         struct address_space *mapping,
                         loff_t pos,
                         unsigned len,
                         unsigned copied,
                         struct folio *folio,
                         void *fsdata)
{
    return copied;
}

void reiser4_nx_invalidate_folio(struct folio *folio,
                                 size_t offset,
                                 size_t length)
{
}

bool reiser4_nx_release_folio(struct folio *folio, gfp_t gfp)
{
    return true;
}

int reiser4_nx_migrate_folio(struct address_space *mapping,
                             struct folio *dst,
                             struct folio *src,
                             enum migrate_mode mode)
{
    return 0;
}
