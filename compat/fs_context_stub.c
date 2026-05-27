#include <linux/fs_context.h>
#include <linux/fs.h>
#include "../super.h"

/*
 * Linux 7.x fs_context bridge
 *
 * Reiser4 still uses the classic:
 *
 *     fill_super(struct super_block *, void *, int)
 *
 * mount model.
 *
 * Modern kernels expect:
 *
 *     get_tree_bdev()
 *     fs_context_operations
 *
 * This adapter layer bridges the old Reiser4 mount pipeline
 * into the modern fs_context API.
 */

static int reiser4_fill_super_fc(struct super_block *sb,
                                 struct fs_context *fc)
{
    return reiser4_fill_super(sb, (void *)fc->source, 0);
}

static int reiser4_get_tree_fc(struct fs_context *fc)
{
    return get_tree_bdev(fc, reiser4_fill_super_fc);
}

static const struct fs_context_operations reiser4_context_ops = {
    .get_tree = reiser4_get_tree_fc,
};

int reiser4_init_fs_context(struct fs_context *fc)
{
    fc->ops = &reiser4_context_ops;
    return 0;
}
