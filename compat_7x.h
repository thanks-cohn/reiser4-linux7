#ifndef REISER4_COMPAT_7X_H
#define REISER4_COMPAT_7X_H

#include <linux/mm.h>
#include <linux/pagemap.h>
#include <linux/bio.h>
#include <linux/blk_types.h>

#ifndef page_index
#define page_index(page) (page_folio(page)->index)
#endif

#ifndef PageError
#define PageError(page) (!folio_test_uptodate(page_folio(page)))
#endif

#ifndef SetPageError
#define SetPageError(page) do { } while (0)
#endif

#ifndef ClearPageError
#define ClearPageError(page) do { } while (0)
#endif

#ifndef set_page_dirty_notag
#define set_page_dirty_notag(page) set_page_dirty(page)
#endif

#ifndef bio_set_op_attrs
#define bio_set_op_attrs(bio, op, flags) \
do { \
    (bio)->bi_opf = (op) | (flags); \
} while (0)
#endif

#ifndef bdi_write_congested
#define bdi_write_congested(bdi) (0)
#endif

#endif
