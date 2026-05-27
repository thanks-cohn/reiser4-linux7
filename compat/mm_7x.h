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

#endif

/* wait_on_page_locked modernization */
#ifndef wait_on_page_locked
#define wait_on_page_locked(page) folio_wait_locked(page_folio(page))
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


/* -------------------------------------------------- */
/* temporary Linux 7 pagevec compatibility            */
/* -------------------------------------------------- */


struct pagevec {
    unsigned int nr;
    struct page *pages[PAGEVEC_SIZE];
};

static inline void pagevec_init(struct pagevec *pvec)
{
    pvec->nr = 0;
}

static inline void pagevec_release(struct pagevec *pvec)
{
    pvec->nr = 0;
}




/* -------------------------------------------------- */
/* durable page index abstraction                     */
/* -------------------------------------------------- */

static inline pgoff_t reiser4_page_index(struct page *page)
{
    return page_folio(page)->index;
}

#define page_index(page) reiser4_page_index(page)

