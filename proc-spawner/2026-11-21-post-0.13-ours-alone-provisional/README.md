# PROVISIONAL: Proc::ShellSpawn alone over the corpus, 0.13's code against post-0.13's (2026-11-20 and 2026-11-21)

**Provisional.**  Only Proc::ShellSpawn ran; dash and `bash --posix` were not run again, and their
results are those of [`../2026-11-17-post-0.12/`](../2026-11-17-post-0.12/).  The corpus tables of
Proc-Spawner's documents (its `README.md`, "How close"; `large-subset-state.md`, section 7;
`large-subset-environment.md`, sections 9 to 12) are made from that collection, not from this one.  This
one stands until a full `make corpus-all` with the code of post-0.13 exists; that run's collection
replaces it.

Where the code and the text that use it are: the commits named below are in Proc-Spawner's branch
`post-0.13-todo` (on 2026-11-22 only there, apart from `0542161`, 0.13's code, which is on `main` too).
That branch's `Changes`, entry post-0.13, has the counts of this collection, and its
`doc/test-results/linux-flavors-by-test.txt` is `checks2/by-test-full.txt` (below).

`records.tar.xz` (3 MB; about 90 MB unpacked) holds the directories and files that these runs left
in Proc-Spawner's `corpus-work/`.  `CONTENTS.txt` lists them with their sizes.

## What was measured

Whether the changes made to the shell layer after 0.13 changed what Proc::ShellSpawn does with the
40,410 snippets that the runs of 2026-11-17 took, and how.

Each run: `large-subset-runcompare.pl -j 4 -env tmp,random,mtime -base /runcompare -shells ours
-workers-from corpus-work/run samples.jsonl samples.tsv OUTDIR`, as root under `unshare -n`, so
that each snippet ran in the worker (directory and user) it had on 2026-11-17.  The samples and the
workers are those of the collection of 2026-11-17.  A record is one JSON line per snippet, of the
form described in [`../2026-11-17-post-0.12/README.md`](../2026-11-17-post-0.12/README.md), "The
records", with the part `ours` only.

| Directory | Code | When (UTC) |
|---|---|---|
| `ours-old/` | 0.13 (Proc-Spawner commit `0542161`) | 2026-11-20, 22:02 to 22:30 |
| `ours-new/` | post-0.13, commit `6967522` (X30, X6, X73, `cd -`, X74, X56 in the executor, X75, X3, X4) | 2026-11-20, 22:30 to 23:00 |
| `ours-new2/` | post-0.13, commit `67c9933` (also X72 worded as dash, and the base grammar refusing `exec` with a builtin's name) | 2026-11-21, 07:38 to 08:08 |

`ours-old/`, `re-old-*/` and `re2-old-*/` ran from a checkout of 0.13 in `/home/user/ps-old` (their
`programs.txt` names that path), the others from the session's clone of the branch.  The code of
post-0.13 still has `$VERSION` 0.13, so the logs of `checks/` and `checks2/` say "0.13" for it too.
(The labels X30, X72, ... are Proc-Spawner's known issues, `doc/pspawn-known-issues.md`.)  Both
comparisons are against `ours-old`: the second compares `ours-new2`, not `ours-new`, with 0.13's code.

A snippet whose result differs between two full runs may differ by chance (process IDs, dates,
random numbers, races).  So the snippets that differed were run again, twice with each code:
`re-old-a/`, `re-new-a/`, `re-old-b/`, `re-new-b/` for the first comparison (the 62 snippets of
`changed62.ids`), `re2-old-a/` ... `re2-new-b/` for the second (the 72 of `changed2.ids`).  Each
snippet of a list then falls into exactly one of three groups, from four comparisons of the reruns:

- *changed by the code*: ShellSpawn differs between the two codes in both reruns (`re-new-a` against
  `re-old-a`, and `re-new-b` against `re-old-b`), and not between the two reruns of one code;
- *noise*: ShellSpawn differs between the two reruns of one code (`re-old-b` against `re-old-a`, or
  `re-new-b` against `re-new-a`);
- *the same in every rerun*: none of the four comparisons shows a difference.

The full runs are not counted among the runs of one code: they only chose the snippets to rerun.

## How two results are compared

By Proc-Spawner's `large-subset-runreport.pl` with `-ours-vs` (in `doc/large-subset/tools/`), ShellSpawn
against ShellSpawn, snippet by snippet.  The parts compared:

- `status`, `out` and `files`, as recorded;
- `rec`, the programs called, with its lines sorted (the elements of a pipeline run at once and log
  in any order);
- `err`, the messages: `sh: ` (Proc::ShellSpawn's prefix) taken off the start of each line, the
  newlines dropped, and the characters sorted, so that the same messages in another order, or
  interleaved by the elements of a pipeline, compare equal, while other wording does not.

A snippet differs when any of these does.  A result that ran out of time (status 124) is compared as
any other.  The classes of `../2026-11-17-post-0.12/` (its README, "How the reports compare the
shells") reduce the parts the same way, with each shell's own prefix, but leave out a snippet where a
shell ran out of time.

## What came out

| | `ours-new` against `ours-old` | `ours-new2` against `ours-old` |
|---|---|---|
| differ in the full runs | 62 | 72 |
| differ between two runs of one code (noise) | 45 | 46 |
| the same in every rerun | 6 | 8 |
| changed by the code | 11 | 18 |

45 + 6 + 11 = 62 and 46 + 8 + 18 = 72.

- The 11 (`real`): the 2 snippets with `cd -` (the directory is printed, as dash prints it); `exec
  command -with -flags` (status 127, as both shells; it was 248, the status of what Proc::ShellSpawn does not support: `'command -with' is not supported`);
  8 more snippets with `exec`, whose message alone changed (`exec: ` in front; in `NB:1757` the
  message goes to standard output, through `2>&1`, so the part that differs there is `out`).
  2 + 1 + 8 = 11.
- The 18 (`real2`): those 11, with `exec command -with -flags` now refused by the grammar (status 255
  from the test driver, Proc-Spawner's `t/try.pl`: the code of the first comparison did there what both
  shells do, that of the second does not); and 7 snippets whose message alone changed: a
  command whose name is empty (`"$outfile"` with the variable unset) says `Permission denied`, as
  dash says for it, where it said `not found`.  11 + 7 = 18.
- The same in every rerun: 5 snippets read `/etc/group`, `/usr` or `/etc`, which an installation of
  packages changed in the container on 2026-11-20 at 22:34, during the run of `ours-new`; the
  others differed in the full runs only (1 race in the first comparison, 3 snippets' messages in
  the second).  5 + 1 = 6 and 5 + 3 = 8.

The files:

- `changed62.ids`, `changed2.ids`: the snippets that differ in the full runs (62, 72), one id a line.
- `real` (11) and `noise` (45): the first comparison's groups; its 6 the same in every rerun have no
  file (`changed62.ids` without `real` and `noise`).  `real2` (18), `noise2` (46) and `never2` (8,
  the same in every rerun): the second comparison's.
- `ours-new-vs-old.txt`: the tool's whole output for the first comparison of the full runs.  Its first
  part is a table of classes, ShellSpawn of `ours-new` against dash and bash of 2026-11-17 (the columns of
  `runreport.txt` of `../2026-11-17-post-0.12/`, explained there, without its column `chance`).  Its
  second part (headed "Ours against ours", as the tools printed it then) is one line per snippet that differs: the id, the parts that
  differ, ShellSpawn's status in `ours-old` -> in `ours-new`, "shells too" (always empty: the shells were not
  run again), and the start of the text.
- `ours-new2-vs-old.txt`: only that second part, for the second comparison.
- `cmp-A-vs-B.txt` (the first comparison's reruns) and `cmp2-A-vs-B.txt` (the second's): the second
  part, for rerun A against rerun B (the status column reads B -> A).  `summary2.txt`: the second comparison's counts, and the lines of its 18
  changed by the code and of its 8 the same in every rerun.

**The table of classes says little.**  It joins ShellSpawn of 2026-11-20 with the shells of 2026-11-17, run
in a container whose system files had changed in between.  Joined so, even 0.13's own code
(`ours-old`) turns 20 snippets that agreed in all three on 2026-11-17 into "dash and bash agree, ShellSpawn
differs" (`OURS`): they read `/etc/passwd`, `/etc/group`, `/lib`, `/proc/config.gz`, or print dates
and times.  So `OURS` is 27 in that table, against 4 (and 3 known chance) in the base run.  Compare
ShellSpawn with ShellSpawn, as the second part does, or run the shells again.

## Also inside

- `checks/` (2026-11-20, commit `283995a`: `6967522` and one commit more, `6d3f345`, which changed only
  Proc::Spawner's `closefrom`, not the shell layer, then documents): the tests at the four levels of the spawn primitive (`t/flavors.pl`;
  `checks.log`, `flavors.out`, `linux-flavors.txt`); the per-test outcomes of each level (`L1.tsv`
  to `L4.tsv`, compared in `by-test.txt` and, with a header, `by-test-full.txt`); `make disttest`
  with and without `/proc` (`disttest.out`, `disttest-noproc.out`); the fuzzer (Proc-Spawner's `make probe-fuzz`: random
  snippets made of pieces of the corpus, run by dash, bash and ShellSpawn; each snippet's class and text, then
  each shell's status and output), three seeds (11, 12, 13), with 0.13's code and with the new one
  (`fuzz-old-N.out`, `fuzz-new-N.out`): seed 12 gives the same, and in seeds 11 and 13 only dash's or
  bash's own results differ (a signal, a race), not ShellSpawn.  `L1.out` to `L4.out` and `compare.err` are
  empty; `level2-missing.txt` names the settings that level 2 takes as missing.
- `checks2/` (2026-11-21, commit `67c9933`): the same tests at the four levels and per test
  (`final.log`, which also logs the run `ours-new2`), and the build and tests
  under Wine (`wine-build.out`); no `make disttest` and no fuzzer this time.
- The columns of `L1.tsv` to `L4.tsv`: the level (`L1-as-built`, `L2-redirections-only`, `L3-fork`,
  `L4-system1`), the test file, the test's number (0: the file as a whole), the outcome (`ok`,
  `SKIP`, `FILE-SKIPPED`, ...), the test's description, the reason of a skip.  No test failed at
  any level, in either directory; some are skipped at each level (`SKIP`, `FILE-SKIPPED`).
- `oursrun.log`: when the full runs `ours-old` and `ours-new` started and ended (UTC); `ours-new2`'s
  are in `checks2/final.log` ("rebuilt" 07:38, the run's end 08:08).

## How to use it

```bash
cd Proc-Spawner && mkdir -p corpus-work && tar -xJf /path/to/records.tar.xz -C corpus-work
```

beside the unpacked collection of 2026-11-17, which has `run/`, `samples.jsonl` and `samples.tsv`.
Then, for example, `perl doc/large-subset/tools/large-subset-runreport.pl -ours-from
corpus-work/ours-new2 -ours-vs corpus-work/ours-old corpus-work/run` gives `ours-new2-vs-old.txt`
again, after the table of classes.
