# Reiser4-Linux7 Release Gates

This file defines project-wide release discipline. It does **not** claim that V3, V4, V5, or V6 has been reached.

## Non-Negotiable Gate Rules

1. **No milestone without a script.**
   - A status document can describe a target, but the milestone is not achieved until a runnable gate script exists in `scripts/` or `tests/`.
   - The script must produce a clear pass/fail result and preserve enough logs to debug failure.
2. **No script pass without `dmesg` review.**
   - A gate script must scan kernel logs for at least: `BUG`, `Oops`, `panic`, `null pointer`, `WARNING`, and `use-after-free`.
   - A human reviewer must still inspect the saved `dmesg` artifact before accepting a milestone.
3. **No personal-use claim without remount verification.**
   - V3 requires a clean unmount, remount, post-remount data verification, final unmount, and dangerous-`dmesg` scan.
   - A single mount-session write/read pass is not enough for V3.
4. **No production-value claim without crash consistency, recovery, and supported workload boundaries.**
   - V6 requires a documented crash-consistency story, recovery/fsck evidence, power-loss testing, and explicit safe/unsafe workload boundaries.
   - V6 must also name supported kernel and reiser4progs versions.

## Gate Scripts by Milestone

| Milestone | Required gate script | Required evidence |
| --- | --- | --- |
| V0 Alive | `scripts/reiser4-alpha-smoke-test.sh` | Build/load/format/mount/basic IO evidence. |
| V1 Basic Lifecycle | `scripts/reiser4-v1-smoke.sh` | Basic lifecycle transcript plus `dmesg` review. |
| V2 Stress-Hardened Lab | `tests/stress_reiser4_v2.sh` | Repeated lifecycle and operation stress plus `dmesg` review. |
| V3 Personal Experimental Use | `tests/prove_reiser4_v3.sh` | V1 gate, mkdir regression, small-file/rename/delete/remount stress, clean unmount, `rmmod`, and `dmesg` scan. |
| V4 Daily Driver Candidate | TBD | Multi-day dedicated-machine gate, backup/restore drill, and workload replay. |
| V5 Public Beta | TBD | Reproducible CI matrix, issue templates, and public beta workload envelope. |
| V6 Production-Value Candidate | TBD | Crash consistency, recovery/fsck, power-loss, security review, and supported workload matrix. |

## Failure Handling

When any gate fails:

1. Preserve the command transcript and kernel log.
2. Run `tools/reiser4_failure_bundle.sh` where possible.
3. Add or update an entry in `docs/status/FAILURE_REGISTRY.md`.
4. Do not advance the milestone until a subsequent run proves the failure is fixed.

## Current Gate Interpretation

The presence of `scripts/reiser4-v3-mkdir-regression.sh` and `tests/prove_reiser4_v3.sh` means V3 has a proof path. It does **not** mean V3 has been achieved. V3 is reached only when `tests/prove_reiser4_v3.sh` passes on a documented host and its `dmesg` artifact is clean.
