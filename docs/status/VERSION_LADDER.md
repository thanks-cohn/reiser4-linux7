# Reiser4-Linux7 Version Ladder

This ladder defines the project milestones from first signs of life through a production-value candidate. A milestone is not real unless its matching gate script exists, passes, and the saved `dmesg` evidence is reviewed. This document does **not** claim V3 or any later milestone.

## V0 Alive

**Meaning:** the port is alive enough to prove that the code can be built, loaded, formatted, mounted, and used for minimal regular-file IO on a disposable image.

**Minimum evidence:**

- Module builds against the target kernel headers.
- `reiser4.ko` loads.
- `mkfs.reiser4` formats a loopback image.
- Filesystem mounts.
- A regular file can be created, written, read, and synced.

**Gate:** `scripts/reiser4-alpha-smoke-test.sh`.

## V1 Basic Lifecycle

**Meaning:** one complete basic filesystem lifecycle works on a disposable loopback image.

**Required operation sequence:**

```text
mkfs -> mount -> mkdir -> create -> write -> read -> rename -> delete -> sync -> unmount -> remount -> verify -> unmount -> rmmod
```

**Gate:** `scripts/reiser4-v1-smoke.sh`.

## V2 Stress-Hardened Lab

**Meaning:** the basic lifecycle survives repeated lab stress on disposable loopback images.

**Required evidence:**

- Repeated create/read/write/rename/delete loops.
- Repeated mount, unmount, and remount cycles.
- Nested directory operations.
- Many-small-file churn.
- Clean `dmesg` review after the run.

**Gate:** `tests/stress_reiser4_v2.sh`.

## V3 Personal Experimental Use

**Meaning:** loopback-only personal experimental use is proven by a dedicated V3 proof wrapper. V3 is not reached by passing one mkdir test.

**Required evidence:**

- V1 gate passes inside the V3 proof wrapper.
- `scripts/reiser4-v3-mkdir-regression.sh` passes inside the V3 proof wrapper.
- Many-small-files test passes.
- Rename/delete test passes.
- Repeated remount verification passes.
- Clean unmount passes.
- `rmmod` passes when the module was loaded by the gate.
- `dmesg` scan is clean for `BUG`, `Oops`, `panic`, `null pointer`, `WARNING`, and `use-after-free`.

**Gate:** `tests/prove_reiser4_v3.sh`.

## V4 Daily Driver Candidate

**Meaning:** the filesystem may be considered for a backed-up dedicated test machine, but not for general public beta or production-value use.

**Required evidence:**

- Multi-day workload replay on a dedicated test machine.
- Backup and restore drill.
- Reboot/remount cycles.
- Source-tree, package-cache, archive, and large-directory workloads.
- No unreviewed dangerous stubs on the supported path.

**Gate:** TBD; must be added before V4 can be claimed.

## V5 Public Beta

**Meaning:** the project is ready for public beta testers using explicit workload boundaries and full failure-reporting discipline.

**Required evidence:**

- Reproducible CI/build matrix.
- Public issue and crash-report templates.
- Known-good and known-bad kernel list.
- Known safe and unsafe workload list.
- Upgrade/downgrade/recovery notes.

**Gate:** TBD; must be added before V5 can be claimed.

## V6 Production-Value Candidate

**Meaning:** the filesystem has a defensible production-value story for explicitly supported kernels, reiser4progs versions, storage backends, and workloads. This is still a candidate label, not a blanket production guarantee.

**Required evidence:**

- Supported kernel matrix.
- CI/build matrix.
- Crash-consistency testing.
- Power-loss testing.
- Recovery/fsck story.
- Security review.
- Temporary stub removal or classification.
- Explicit known safe and unsafe workloads.
- Tagged-release discipline and retained artifacts.

**Gate:** TBD; must be added before V6 can be claimed.
