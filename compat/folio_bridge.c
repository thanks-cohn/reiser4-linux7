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

int reiser4_nx_write_begin(struct file *file,
struct address_space *mapping,
loff_t pos,
unsigned len,
struct page **pagep,
void **fsdata)
{
    return 0;
}

int reiser4_nx_write_end(struct file *file,
struct address_space *mapping,
loff_t pos,
unsigned len,
unsigned copied,
struct page *page,
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
	bool ret;

	printk(KERN_ERR
	"REISER4_RELEASE_FOLIO folio=%p index=%lu dirty=%d writeback=%d private=%d mapped=%d\n",
	folio,
	folio->index,
	folio_test_dirty(folio),
	folio_test_writeback(folio),
	folio_test_private(folio),
	folio_mapped(folio));

	ret = try_to_free_buffers(folio);

	printk(KERN_ERR
	"REISER4_RELEASE_RESULT folio=%p ret=%d private=%d dirty=%d writeback=%d\n",
	folio,
	ret,
	folio_test_private(folio),
	folio_test_dirty(folio),
	folio_test_writeback(folio));

	return ret;
}

int reiser4_nx_migrate_folio(struct address_space *mapping,
                             struct folio *dst,
                             struct folio *src,
                             enum migrate_mode mode)
{
    return 0;
}
