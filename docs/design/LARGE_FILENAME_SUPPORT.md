# Large Filename Support Strategy

Reiser4-NX keeps the long-name dream alive, but this pass is research,
documentation, probes, and audit tooling only. It does not change lookup,
mkdir, rename, dentry handling, `qstr` handling, VFS-facing validation,
directory item layout, or on-disk format.

## A. Historical Ambition

Reiser4 has long been associated with unusually large filename ambitions,
commonly cited around approximately 3976-byte filename component support. That
ambition matters because it points at a filesystem that can preserve human
meaning instead of forcing memory, context, and intent into tiny labels.

The common modern Linux baseline is much smaller. ext4, for example, exposes a
255-byte filename component limit, and many Linux tools have been built and
tested around that kind of boundary. A filename component that is ordinary for
Reiser4's historical dream may be extraordinary to userspace, test suites,
backup tools, file managers, and kernel paths that have never had to handle it.

Reiser4-NX must eventually pursue expressive, human-scale names without
sacrificing stability. The project goal is not merely to be another filesystem
with the same cramped naming model. The goal is to earn the right to preserve
larger meaning after the safety, recovery, and compatibility story is proven.

## B. Current Linux Reality

Linux does not consist only of an on-disk directory item format. Filename
behavior passes through userspace, libc wrappers, shell quoting and expansion,
archive tools, sync tools, backup tools, file managers, VFS pathname walking,
dentry allocation, `struct qstr`, filesystem lookup methods, and error-handling
paths. Many of these components commonly assume 255-byte filename components,
`NAME_MAX`-like component limits, or `PATH_MAX`-like whole-path limits even when
a particular interface can theoretically carry more data.

Unsafe oversized dentry hacks are not acceptable. A hack that makes one create
operation appear to work could still corrupt directory state, truncate names,
confuse negative dentries, break rename/unlink semantics, overflow internal
buffers, make backup tools silently skip data, or create false confidence that
names are durable when they do not survive remount, fsck, export, restore, or
recovery. A successful demo is not enough; long names must either work safely
through the full lifecycle or fail safely with documented errors.

## C. Two-Track Strategy

### Track A: Native Large POSIX Names

Native large POSIX names means exposing filename components larger than the
normal Linux `NAME_MAX` boundary through ordinary VFS paths. Reiser4-NX must not
claim this until the constraints are researched and tested.

Before implementation, the project must identify at least these constraint
classes:

- Kernel pathname lookup behavior and where component length is validated.
- VFS, dentry, and `qstr` assumptions about component length and hashing.
- Filesystem method expectations for lookup, create, mkdir, link, unlink,
  rename, readdir, and directory item packing.
- Userspace behavior in libc, shells, tar, rsync, file managers, backup tools,
  source-control tools, and language runtimes.
- Whole-path interactions with `PATH_MAX`-style callers even if individual
  components are accepted.
- Remount, fsck/recovery, export, import, and migration behavior.

Native 3976-ish byte names are therefore a future experimental path, not a
current claim. Any future native attempt must be behind an explicit experimental
mount option, must default off, must be rejected on unsupported kernel/tool
combinations, and must be guarded by probes, stress tests, remount tests,
recovery tests, backup/restore drills, and dmesg scanning.

### Track B: Reiser4-NX True Names

The safer compatibility path is a future true-name layer. Each file can have two
names:

1. A POSIX-visible safe name that obeys normal Linux and tool expectations.
2. A Reiser4-NX true name up to at least 4000 characters.

The POSIX-visible safe name is the interoperability passport. The true name is
where full human meaning can live without forcing every VFS and userspace path
to accept enormous components immediately.

A true-name design must make true names:

- Searchable by Reiser4-NX tooling.
- Exportable into a manifest when data leaves Reiser4-NX.
- Importable from that manifest when data returns.
- Recoverable after clean and dirty remount scenarios.
- Restorable after backup and restore.
- Durable across remount and fsck/recovery.
- Auditable so safe names and true names can be reconciled.

When moved to ext4, XFS, Btrfs, ZFS, or another filesystem that cannot safely
hold the native true name as a POSIX component, tooling should create safe
shortened names plus a manifest preserving the full true name, stable identity,
content metadata, and collision-resolution information. When imported back to
Reiser4-NX, tooling should use that manifest to restore the true name rather
than treating the shortened compatibility name as the final meaning.

The true-name layer still needs design before implementation. Open questions
include metadata location, indexing, collision handling, fsck behavior,
interaction with xattrs or plugins, manifest schema, integrity protection,
rename semantics, and recovery ordering.

## D. Doctrine

- Stability first.
- Data safety first.
- Recovery first.
- Beauty after proof.
- The POSIX name is the passport.
- The Reiser4-NX true name is the soul.
- We obey Linux where we must.
- We transcend Linux where meaning can live safely.
