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
