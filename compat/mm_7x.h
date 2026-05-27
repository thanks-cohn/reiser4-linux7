#ifndef REISER4_MM_7X_H
#define REISER4_MM_7X_H

#include <linux/mm.h>
#include <linux/pagemap.h>
#include <linux/pagevec.h>

/*
 * Linux 7.x MM compatibility layer
 */

/* page->index compatibility */
#ifndef page_index
#define page_index(page) ((page)->index)
#endif

/* wait_on_page_locked modernization */
#ifndef wait_on_page_locked
#define wait_on_page_locked(page) wait_on_page_bit(page, PG_locked)
#endif

/* zero_user modernization */
#ifndef zero_user
#define zero_user(page, start, size) \
    folio_zero_range(page_folio(page), start, size)
#endif

/* pagevec compatibility */
#ifndef pagevec_count
#define pagevec_count(pvec) ((pvec)->nr)
#endif

#ifndef pagevec_space
#define pagevec_space(pvec) (PAGEVEC_SIZE - (pvec)->nr)
#endif

#endif
