# STRESS TEST IT MUST PASS

These tests are designed to provide a practical standard of guidance, confidence, and engineering pressure for Reiser4-NX as it matures toward being a secure, dependable, and capable filesystem. They do not magically guarantee safety, but they define the kind of evidence a filesystem should produce before anyone begins to trust it with precious data. The purpose of this document is to turn confidence into proof, proof into repeatable tests, and repeatable tests into long-term assurance.

Passing this list once is not enough for production trust. These tests should be treated as a living proving range: every failure must produce logs, every fix must gain a regression test, and every milestone must be earned through repeated clean runs across kernels, storage backends, and real workloads.

## Life-Files Grade Stress Test Proposals

1. Verify the full V3 proof script passes 100 times in a row on a clean Ubuntu LTS VM with no dangerous dmesg output.

2. Verify the full V3 proof script passes overnight for at least 12 hours without a kernel BUG, Oops, panic, warning storm, or stuck module reference.

3. Verify the full V3 proof script passes continuously for 72 hours on loopback storage.

4. Verify the same 72-hour test passes on a sacrificial physical SSD partition.

5. Verify the same 72-hour test passes on a sacrificial physical HDD partition.

6. Verify the same 72-hour test passes on NVMe storage.

7. Verify the filesystem survives 30 consecutive days of nightly stress testing with artifacts saved for every run.

8. Verify every nightly run records kernel version, git commit, compiler version, reiser4progs version, hardware backend, and pass/fail state.

9. Verify every failure automatically produces a complete failure bundle with dmesg, mount state, loop state, module state, git state, and test logs.

10. Verify every test failure is reproducible from a clean boot or documented as non-reproducible with evidence.

11. Verify the filesystem survives 10,000 mount-write-sync-unmount-remount-verify cycles.

12. Verify the module can be loaded, used, unloaded, rebuilt, reloaded, and reused 1,000 times without reboot.

13. Verify no entd, ktxnmgrd, or related Reiser4 kernel thread survives after clean unmount and rmmod.

14. Verify no Reiser4 slab objects grow without bound during long stress runs.

15. Verify no memory leak appears under kmemleak or equivalent kernel leak detection after repeated mount/unmount cycles.

16. Verify no lockdep warnings appear during concurrent filesystem workloads.

17. Verify no KASAN warnings appear under a KASAN-enabled kernel build.

18. Verify no UBSAN warnings appear under a UBSAN-enabled kernel build.

19. Verify no KCSAN data-race warnings appear during concurrent create, rename, delete, and fsync workloads.

20. Verify the filesystem survives fsx-style randomized file operation testing for at least 24 hours.

21. Verify the filesystem survives fsstress-style metadata torture for at least 24 hours.

22. Verify the filesystem survives parallel fsstress instances across multiple directories.

23. Verify randomized create, write, truncate, rename, unlink, symlink, hardlink, chmod, chown, and fsync operations preserve a mirrored oracle model.

24. Verify every file written by the oracle model matches byte-for-byte after remount.

25. Verify the oracle model still matches after unmount, module unload, module reload, and remount.

26. Verify the oracle model still matches after a clean reboot.

27. Verify the oracle model still matches after an intentionally dirty reboot on sacrificial hardware.

28. Verify the oracle model still matches after power-cut testing at random points during write-heavy workloads.

29. Verify the filesystem either recovers safely or fails safely after simulated power loss during metadata-heavy mkdir, rename, and delete storms.

30. Verify the filesystem either recovers safely or fails safely after simulated power loss during large sequential writes.

31. Verify the filesystem either recovers safely or fails safely after simulated power loss during small random writes.

32. Verify the filesystem either recovers safely or fails safely after simulated power loss during truncate operations.

33. Verify the filesystem either recovers safely or fails safely after simulated power loss during fsync-heavy workloads.

34. Verify fsck.reiser4, or the available recovery toolchain, can inspect the filesystem after clean unmount without false corruption reports.

35. Verify the recovery toolchain can inspect the filesystem after dirty shutdown and provide a clear, documented result.

36. Verify the recovery toolchain can repair known recoverable damage on sacrificial test images.

37. Verify repair never makes a clean filesystem worse.

38. Verify repair never silently destroys files without reporting the loss.

39. Verify repair outcomes are checked against a pre-crash manifest of file paths, sizes, hashes, modes, owners, and timestamps.

40. Verify a million-file tree can be created, scanned, synced, unmounted, remounted, and verified.

41. Verify a million-file tree can be partially deleted, synced, remounted, and verified.

42. Verify a million-file tree can be renamed in batches without directory corruption.

43. Verify directory lookup remains correct in very large directories with hundreds of thousands of entries.

44. Verify repeated find, du, tar, rsync, and cp -a operations over large trees complete without errors.

45. Verify a real source tree workload can clone, checkout, build, clean, delete, remount, and verify.

46. Verify a Linux kernel source tree can be unpacked, built, cleaned, deleted, remounted, and verified.

47. Verify a large Git repository can perform clone, branch checkout, status, commit, gc, fsck, delete, remount, and verify.

48. Verify package-manager-like workloads with many small files and atomic renames behave correctly.

49. Verify browser-cache-like workloads with many concurrent small writes and deletes behave correctly.

50. Verify photo-library-like workloads with many medium binary files preserve exact hashes after repeated moves and remounts.

51. Verify archive workloads can create, extract, compare, delete, and recreate tarballs without corruption.

52. Verify VM-image-like large sparse files preserve hole structure and data extents after remount.

53. Verify database-like workloads using SQLite with synchronous mode survive crash tests according to SQLite integrity checks.

54. Verify maildir-like workloads with many small files, renames, and fsyncs preserve message counts and hashes.

55. Verify rsync backup workloads preserve file hashes, hardlinks, symlinks, permissions, ownership, and timestamps.

56. Verify encrypted-container files stored on Reiser4 remain byte-for-byte stable across long stress and remount cycles.

57. Verify permissions, ownership, ACLs if supported, and extended attributes if supported survive remount and fsck.

58. Verify unsupported features fail clearly instead of pretending to work.

59. Verify read-only mount never dirties the filesystem.

60. Verify remount read-only flushes all required state and leaves the filesystem consistent.

61. Verify ENOSPC behavior under tiny, medium, and large filesystem sizes fails cleanly without metadata corruption.

62. Verify recovery after ENOSPC allows deletion, sync, continued writes, unmount, and remount.

63. Verify inode exhaustion or equivalent metadata exhaustion fails cleanly.

64. Verify absurdly long filenames fail safely at the correct boundary.

    Reiser4-NX must eventually test the historical large filename dream explicitly, including 255, 256, 512, 1024, 2048, 3976, 4032, and 4096 byte component probes, and must either support them safely or fail safely with documented behavior.

65. Verify absurdly long paths fail safely at the correct boundary.

66. Verify Unicode filenames, spaces, newlines, shell-hostile names, and mixed encodings do not corrupt directory listings.

67. Verify case-sensitive behavior is consistent and documented.

68. Verify hardlink counts remain correct after complex link and unlink sequences.

69. Verify symlink loops are handled by VFS correctly without filesystem-specific corruption.

70. Verify concurrent writers to the same file behave according to Linux semantics and do not corrupt unrelated files.

71. Verify concurrent appenders preserve expected append behavior under heavy parallelism.

72. Verify concurrent rename and lookup races do not expose stale, duplicated, or impossible directory entries.

73. Verify concurrent unlink while open preserves file lifetime until the last handle closes.

74. Verify mmap read and mmap write workloads behave correctly if supported.

75. Verify pagecache behavior remains correct after mmap, msync, truncate, writeback, and remount.

76. Verify direct I/O either works correctly or is rejected safely and documented.

77. Verify fallocate either works correctly or is rejected safely and documented.

78. Verify reflink, compression, encryption, or plugin-specific features either work correctly or are explicitly marked unsupported.

79. Verify all Reiser4 plugin combinations intended for support have separate smoke and stress tests.

80. Verify every temporary bypass, dangerous stub, suspicious return 0, and BUG_ON in critical paths is classified before production-value claims.

81. Verify the danger scanner is clean of unclassified critical-path hazards.

82. Verify every known failure has an entry in FAILURE_REGISTRY.md with status, trigger, suspected function, and next action.

83. Verify every fixed failure has a regression test that fails before the fix and passes after the fix.

84. Verify the test matrix covers every supported kernel version.

85. Verify the test matrix covers every supported compiler version or documents the compiler boundary.

86. Verify the test matrix covers every supported reiser4progs version.

87. Verify the filesystem behaves consistently across kernel minor updates inside the supported Ubuntu LTS line.

88. Verify the module refuses or warns clearly on unsupported kernel versions if compatibility is unknown.

89. Verify build, install, test, uninstall, and cleanup instructions work from a clean clone.

90. Verify a second person can reproduce V1, V2, and V3 results from the documentation alone.

91. Verify a fresh CI runner can at least build and run non-mount static checks.

92. Verify a privileged VM CI runner, if available, can run loopback smoke tests.

93. Verify release artifacts include source commit, build instructions, known-good kernel, known-bad kernels, and test summaries.

94. Verify every release has a signed or checksummed source snapshot and reproducible build notes.

95. Verify public issue templates force reporters to include kernel version, git commit, dmesg, commands, storage backend, and failure bundle.

96. Verify there is a documented backup and migration path off Reiser4 before telling anyone to use it seriously.

97. Verify there is a documented disaster-recovery procedure for damaged filesystems.

98. Verify multiple independent testers run the full V3/V4 suite on different hardware and report matching results.

99. Verify at least one long-term daily-driver test runs for 90 days on backed-up but real workloads without data loss.

100. Verify a final life-files rehearsal migrates a large, hashed, backed-up personal corpus onto Reiser4, runs daily real workloads for 30 days, verifies hashes nightly, tests restore from backup, and only then considers the filesystem worthy of precious data.

## Rule Of Trust

You do not stake life files on one pass.

You begin to trust life files only after repeated passes, dirty shutdown tests, recovery drills, independent reproduction, long-term daily use, and successful restore practice.

The goal is not confidence by declaration.

The goal is confidence by evidence.
