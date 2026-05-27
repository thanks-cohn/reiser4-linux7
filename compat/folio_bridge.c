#include <linux/fs.h>
#include <linux/pagemap.h>
#include <linux/mm.h>
#include <linux/buffer_head.h>

/*
 * Transitional folio bridge for Linux 7.x
 *
 * This adapts Reiser4's page-era address_space_operations
 * into modern folio callbacks.
 */

int reiser4_nx_read_folio(struct file *file, struct folio *folio)
{
    return read_mapping_page(folio->mapping, folio->index, file) ? 0 : 0;
}

bool reiser4_nx_dirty_folio(struct address_space *mapping,
                            struct folio *folio)
{
    filemap_dirty_folio(mapping, folio);
    return true;
}

void reiser4_nx_readahead(struct readahead_control *rac)
{
    /* transitional no-op */
}

int reiser4_nx_write_begin(struct file *file,
                           struct address_space *mapping,
                           loff_t pos,
                           unsigned len,
                           struct page **pagep,
                           void **fsdata)
{
    return block_write_begin(mapping, pos, len, pagep, NULL);
}

int reiser4_nx_write_end(struct file *file,
                         struct address_space *mapping,
                         loff_t pos,
                         unsigned len,
                         unsigned copied,
                         struct page *page,
                         void *fsdata)
{
    return generic_write_end(file, mapping, pos,
                             len, copied, page, fsdata);
}

void reiser4_nx_invalidate_folio(struct folio *folio,
                                 size_t offset,
                                 size_t length)
{
    block_invalidate_folio(folio, offset, length);
}

bool reiser4_nx_release_folio(struct folio *folio, gfp_t gfp)
{
    return try_to_free_buffers(folio);
}

int reiser4_nx_migrate_folio(struct address_space *mapping,
                             struct folio *dst,
                             struct folio *src,
                             enum migrate_mode mode)
{
    return filemap_migrate_folio(mapping, dst, src, mode);
}
