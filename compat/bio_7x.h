#ifndef REISER4_BIO_7X_H
#define REISER4_BIO_7X_H

#include <linux/bio.h>
#include <linux/pagemap.h>
#include <linux/blkdev.h>

/* ------------------------------------------------ */
/* Page error compatibility                         */
/* ------------------------------------------------ */

#ifndef SetPageError
#define SetPageError(page) do { } while (0)
#endif

#ifndef wait_on_page_locked
#define wait_on_page_locked(page) \
    folio_wait_locked(page_folio(page))
#endif

/* ------------------------------------------------ */
/* BIO allocation compatibility                     */
/* ------------------------------------------------ */

static inline struct bio *
reiser4_bio_alloc(gfp_t gfp_mask, unsigned short nr_vecs)
{
    return bio_alloc(NULL, nr_vecs, REQ_OP_READ, gfp_mask);
}

/* ------------------------------------------------ */
/* BIO reset compatibility                          */
/* ------------------------------------------------ */

static inline void
reiser4_bio_reset(struct bio *bio)
{
    bio_reset(bio, NULL, REQ_OP_READ);
}

/* ------------------------------------------------ */
/* bio_set_op_attrs compatibility                   */
/* ------------------------------------------------ */

#ifndef bio_set_op_attrs
#define bio_set_op_attrs(bio, op, flags) \
    ((bio)->bi_opf = (op) | (flags))
#endif

#endif
