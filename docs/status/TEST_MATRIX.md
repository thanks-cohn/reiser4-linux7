# Reiser4-Linux7 Test Matrix

Use this matrix to track proof runs. Do not infer readiness from partial results.

| Suite | Test | Purpose | Pass criterion | Artifact | Current expected result |
| --- | --- | --- | --- | --- | --- |
| V3 personal smoke | `smoke_build_module.sh` | Build module against current kernel headers | clean Kbuild invocation creates reiser4.ko | `artifacts/smoke_build_module-<timestamp>/summary.txt` | Likely expected to pass on Ubuntu 24.04 LTS / Linux 6.8 with matching headers |
| V3 personal smoke | `smoke_module_lifecycle.sh` | Pure insmod, procfs registration, rmmod | module loads, /proc/filesystems lists reiser4, module unloads | `artifacts/smoke_module_lifecycle-<timestamp>/summary.txt` | Expected to pass only from clean boot or clean module state |
| V3 personal smoke | `smoke_mkfs_image.sh` | Fresh loopback mkfs.reiser4 image | mkfs.reiser4 exits 0 | `artifacts/smoke_mkfs_image-<timestamp>/summary.txt` | Expected to pass |
| V3 personal smoke | `smoke_mount_root_stat_unmount.sh` | Mount root, stat root, unmount, rmmod | mount/stat/unmount/rmmod all pass | `artifacts/smoke_mount_root_stat_unmount-<timestamp>/summary.txt` | Expected to pass from clean state |
| V3 personal smoke | `smoke_regular_file_create.sh` | Create a normal root-level file | file create/stat succeeds | `artifacts/smoke_regular_file_create-<timestamp>/summary.txt` | May pass |
| V3 personal smoke | `smoke_regular_file_write_read.sh` | Write known bytes and read exact bytes | sha256 before/after matches | `artifacts/smoke_regular_file_write_read-<timestamp>/summary.txt` | May pass |
| V3 personal smoke | `smoke_regular_file_remount_verify.sh` | Verify file content after remount | hash matches after remount | `artifacts/smoke_regular_file_remount_verify-<timestamp>/summary.txt` | May pass |
| V3 personal smoke | `smoke_rename_file.sh` | Rename file and verify paths | old path gone, new path readable | `artifacts/smoke_rename_file-<timestamp>/summary.txt` | May pass |
| V3 personal smoke | `smoke_delete_file.sh` | Delete file and verify after remount | file remains gone | `artifacts/smoke_delete_file-<timestamp>/summary.txt` | May pass |
| V3 personal smoke | `smoke_mkdir_basic.sh` | Create one directory | mkdir succeeds | `artifacts/smoke_mkdir_basic-<timestamp>/summary.txt` | Currently expected to fail with EPERM until fixed |
| V3 personal smoke | `smoke_nested_directories.sh` | Nested a/b/c/d/e plus file remount verify | nested directories and file persist | `artifacts/smoke_nested_directories-<timestamp>/summary.txt` | Blocked until mkdir passes |
| V3 personal smoke | `smoke_directory_many_entries_small.sh` | 100 files in one directory | count/sample hashes verify after remount | `artifacts/smoke_directory_many_entries_small-<timestamp>/summary.txt` | Blocked until mkdir passes |
| V3 personal smoke | `smoke_sync_pressure_small.sh` | 100 small write/sync operations | no corruption or dmesg danger | `artifacts/smoke_sync_pressure_small-<timestamp>/summary.txt` | Blocked until mkdir and file paths are clean |
| V3 personal smoke | `smoke_repeated_mount_unmount_10.sh` | Mount/unmount same image ten times | all cycles clean | `artifacts/smoke_repeated_mount_unmount_10-<timestamp>/summary.txt` | Expected only from clean state; exposes teardown issues |
| V3 personal smoke | `smoke_module_unload_after_filesystem_use.sh` | Unload after real filesystem use | rmmod succeeds; no ktxnmgrd/entd | `artifacts/smoke_module_unload_after_filesystem_use-<timestamp>/summary.txt` | May expose stuck module/ktxnmgrd |
| V3 personal smoke | `smoke_failed_operation_teardown.sh` | Expected failed op then cleanup | failure does not poison module/loop/thread cleanup | `artifacts/smoke_failed_operation_teardown-<timestamp>/summary.txt` | Failed mkdir may expose stuck module/ktxnmgrd |
| V3 personal smoke | `smoke_dmesg_cleanliness.sh` | Scan dmesg for danger terms | no BUG/Oops/panic/WARNING/etc. | `artifacts/smoke_dmesg_cleanliness-<timestamp>/summary.txt` | Not clean until all required tests run without danger |
| V3 personal smoke | `smoke_fsck_after_clean_unmount.sh` | fsck.reiser4 after clean unmount | fsck clean/acceptable exit | `artifacts/smoke_fsck_after_clean_unmount-<timestamp>/summary.txt` | Not READY_TO_TRY until pass |
| V3 personal smoke | `smoke_v3_short_stress.sh` | Short V3 workload: nested dirs, 500 files, rename/delete, remount verify | operation counts and remount verification pass | `artifacts/smoke_v3_short_stress-<timestamp>/summary.txt` | Blocked until mkdir/teardown are clean |
| V3 personal smoke | `smoke_v3_repeat_from_clean_boot.sh` | Post-reboot repeat of V3 validation | boot recorded, repeat stress passes, final clean state | `artifacts/smoke_v3_repeat_from_clean_boot-<timestamp>/summary.txt` | Final gate; V3 personal status not READY_TO_TRY until pass |

`V3_PERSONAL_SMOKE_STATUS=READY_TO_TRY` is valid only when the suite summary reports all required V3 personal smoke tests passed with no stuck module, no stuck `ktxnmgrd`/`entd`, no stuck loop device, and no dmesg danger.

## V6 production-value smoke suite

These rows define evidence gates only. They do not claim production readiness or V6 readiness until the configured suite passes and artifacts are reviewed.

| Suite | Test | Purpose | Pass criterion | Artifact | Current expected result |
| --- | --- | --- | --- | --- | --- |
| V6 production-value smoke | `v6_smoke_clean_build_matrix.sh` | Build module against current Ubuntu LTS headers | `reiser4.ko` builds and logs warnings, size, sha256, commit | `artifacts/v6_smoke_clean_build_matrix-<timestamp>/summary.txt` | Evidence gate; may pass with matching headers |
| V6 production-value smoke | `v6_smoke_module_lifecycle_100.sh` | 100 clean insmod/rmmod cycles | all cycles unload with no stuck refs or dmesg danger | `artifacts/v6_smoke_module_lifecycle_100-<timestamp>/summary.txt` | Exposes dirty module lifecycle blockers |
| V6 production-value smoke | `v6_smoke_mkfs_mount_unmount_500.sh` | 500 mkfs/mount/stat/unmount/loop detach/rmmod cycles | all cycles clean with no loop/module leaks | `artifacts/v6_smoke_mkfs_mount_unmount_500-<timestamp>/summary.txt` | Exposes mount/teardown blockers |
| V6 production-value smoke | `v6_smoke_full_v1_100.sh` | 100 full V1 lifecycle cycles | create/write/read/rename/delete/remount/verify all pass | `artifacts/v6_smoke_full_v1_100-<timestamp>/summary.txt` | Currently may be blocked by mkdir EPERM |
| V6 production-value smoke | `v6_smoke_v3_proof_30.sh` | Repeat existing V3 proof 30 times | all V3 proof cycles pass with clean dmesg | `artifacts/v6_smoke_v3_proof_30-<timestamp>/summary.txt` | Blocked if V3 proof is absent or failing |
| V6 production-value smoke | `v6_smoke_teardown_after_failure_100.sh` | 100 deliberate harmless failures | cleanup leaves no module/thread/loop state | `artifacts/v6_smoke_teardown_after_failure_100-<timestamp>/summary.txt` | Targets known teardown blockers |
| V6 production-value smoke | `v6_smoke_fsck_clean_and_dirty.sh` | fsck after clean and dirty-style shutdown | fsck outputs and exit codes are predictable | `artifacts/v6_smoke_fsck_clean_and_dirty-<timestamp>/summary.txt` | Required recovery evidence |
| V6 production-value smoke | `v6_smoke_hash_manifest_integrity_100k.sh` | 100k-file hash manifest integrity | no missing/extra/size/hash mismatch after remount | `artifacts/v6_smoke_hash_manifest_integrity_100k-<timestamp>/summary.txt` | Required no-silent-corruption gate |
| V6 production-value smoke | `v6_smoke_directory_scale_1m.sh` | Large directory tree scale | create/list/stat/delete complete with timings | `artifacts/v6_smoke_directory_scale_1m-<timestamp>/summary.txt` | Heavy scale gate |
| V6 production-value smoke | `v6_smoke_nested_tree_depth.sh` | Deep nested tree operations | create/place/rename/delete/remount/fsck survive | `artifacts/v6_smoke_nested_tree_depth-<timestamp>/summary.txt` | Boundary/depth gate |
| V6 production-value smoke | `v6_smoke_rename_delete_storm.sh` | Metadata churn storm | rename/delete/create cycles verify after remount | `artifacts/v6_smoke_rename_delete_storm-<timestamp>/summary.txt` | Corruption/stuck transaction gate |
| V6 production-value smoke | `v6_smoke_parallel_writers.sh` | Concurrent writers/readers | no failed operations, hangs, or hash mismatches | `artifacts/v6_smoke_parallel_writers-<timestamp>/summary.txt` | Concurrency gate |
| V6 production-value smoke | `v6_smoke_large_file_streaming.sh` | Large streaming file | write/sync/read/remount hashes match | `artifacts/v6_smoke_large_file_streaming-<timestamp>/summary.txt` | Large-file gate |
| V6 production-value smoke | `v6_smoke_small_file_pressure.sh` | Many tiny files | sync/remount/fsck/verify no loss or mismatch | `artifacts/v6_smoke_small_file_pressure-<timestamp>/summary.txt` | Metadata pressure gate |
| V6 production-value smoke | `v6_smoke_real_workload_kernel_tree.sh` | Kernel-tree-like workload | copy/unpack/build-like/delete/remount verify | `artifacts/v6_smoke_real_workload_kernel_tree-<timestamp>/summary.txt` | Real workload gate |
| V6 production-value smoke | `v6_smoke_real_workload_git.sh` | Git repository workload | clone/status/add/commit/rename/fsck survives remount | `artifacts/v6_smoke_real_workload_git-<timestamp>/summary.txt` | Real workload gate |
| V6 production-value smoke | `v6_smoke_enospc_inode_exhaustion.sh` | No-space behavior | ENOSPC observed safely; cleanup/remount/fsck pass | `artifacts/v6_smoke_enospc_inode_exhaustion-<timestamp>/summary.txt` | ENOSPC safety gate |
| V6 production-value smoke | `v6_smoke_long_filename_boundaries.sh` | Filename boundary behavior | lengths work or fail safely with remount verification | `artifacts/v6_smoke_long_filename_boundaries-<timestamp>/summary.txt` | Long-name boundary gate, not implementation work |
| V6 production-value smoke | `v6_smoke_powercut_sim_loopback.sh` | Safe loopback dirty interruption | stable pre-crash manifest survives fsck/remount | `artifacts/v6_smoke_powercut_sim_loopback-<timestamp>/summary.txt` | Crash/recovery evidence gate |
| V6 production-value smoke | `v6_smoke_7_day_soak.sh` | Long mixed soak | configured soak completes with clean dmesg/fsck/teardown | `artifacts/v6_smoke_7_day_soak-<timestamp>/summary.txt` | Final soak gate |
