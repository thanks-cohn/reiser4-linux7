#include <linux/fs_context.h>
#include <linux/fs.h>
#include <linux/mount.h>

#include "../super.h"

static int reiser4_get_tree(struct fs_context *fc)
{
    return get_tree_bdev(fc, reiser4_fill_super);
}

static const struct fs_context_operations reiser4_context_ops = {
    .get_tree = reiser4_get_tree,
};

int reiser4_init_fs_context(struct fs_context *fc)
{
    fc->ops = &reiser4_context_ops;
    return 0;
}
