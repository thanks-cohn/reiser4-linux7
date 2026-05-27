
#include <linux/fs_context.h>
#include <linux/fs.h>

int reiser4_init_fs_context(struct fs_context *fc)
{
    return -EOPNOTSUPP;
}
