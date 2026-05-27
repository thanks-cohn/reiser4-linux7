#pragma once

#include <linux/version.h>
#include <linux/fs.h>
#include <linux/pagemap.h>
#include <linux/bio.h>
#include <linux/writeback.h>
#include <linux/blkdev.h>

/*
 * Linux 6.x / 7.x compatibility layer
 *
 * Centralize modern kernel API drift here instead of
 * scattering hacks across filesystem sources.
 */

/* ------------------------------------------------ */
/* Page / folio compatibility                       */
/* ------------------------------------------------ */

#ifndef page_index
#define page_index(page) (page_folio(page)->index)
#endif

#ifndef PageError
#define PageError(page) (!folio_test_uptodate(page_folio(page)))
#endif

#ifndef ClearPageError
#define ClearPageError(page) folio_clear_uptodate(page_folio(page))
#endif

#ifndef set_page_dirty_notag
#define set_page_dirty_notag(page) set_page_dirty(page)
#endif

#ifndef spin_lock_prefetch
#define spin_lock_prefetch(x) prefetchw(x)
#endif

/* ------------------------------------------------ */
/* Writeback compatibility                          */
/* ------------------------------------------------ */

#ifndef bdi_write_congested
#define bdi_write_congested(bdi) 0
#endif

