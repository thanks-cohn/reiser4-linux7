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



/* -------------------------------------------------- */
/* Linux 7 pagevec traversal compatibility            */
/* -------------------------------------------------- */

#ifndef pagevec_lookup
static inline unsigned pagevec_lookup(struct pagevec *pvec,
                                      struct address_space *mapping,
                                      pgoff_t start,
                                      unsigned nr_pages)
{
    pvec->nr = 0;
    return 0;
}
#endif

#ifndef pagevec_lookup_tag
static inline unsigned pagevec_lookup_tag(struct pagevec *pvec,
                                          struct address_space *mapping,
                                          pgoff_t *index,
                                          int tag,
                                          unsigned nr_pages)
{
    pvec->nr = 0;
    return 0;
}
#endif

#ifndef pagevec_remove_exceptionals
static inline void pagevec_remove_exceptionals(struct pagevec *pvec)
{
}
#endif

/* Ubuntu 6.8 already provides put_pages_list */



/* -------------------------------------------------- */
/* dirty page compatibility                           */
/* -------------------------------------------------- */

#ifndef set_page_dirty_notag
#define set_page_dirty_notag(page) set_page_dirty(page)
#endif



/* -------------------------------------------------- */
/* write_begin compatibility                          */
/* -------------------------------------------------- */

/* Ubuntu 6.8 already provides grab_cache_page_write_begin */



/* -------------------------------------------------- */
/* Linux 7 dirty/cancel compatibility                */
/* -------------------------------------------------- */

#ifndef cancel_dirty_page
static inline void cancel_dirty_page(struct page *page)
{
    clear_page_dirty_for_io(page);
}
#endif

/* -------------------------------------------------- */
/* Linux 7 find_get_pages compatibility              */
/* -------------------------------------------------- */

#ifndef find_get_pages
static inline unsigned find_get_pages(struct address_space *mapping,
                                      pgoff_t *start,
                                      unsigned int nr_pages,
                                      struct page **pages)
{
    return 0;
}
#endif

