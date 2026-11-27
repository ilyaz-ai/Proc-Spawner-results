# Proc::ShellSpawn on Windows (under Wine) against the base run on Linux, 2026-11-18/19 (post-0.12)

Proc::ShellSpawn, a module of [Proc-Spawner](https://github.com/ilyaz-ai/Proc-Spawner), runs shell text without a
shell.  The project tests it on 40,410 snippets of shell text (the "large subset"), taken from public sources.  Here
each snippet was run by Proc::ShellSpawn on Windows (under Wine) and compared with the project's base run on Linux:
the run of `make corpus-all` of 2026-11-17, whose records are in
[`../2026-11-17-post-0.12/`](../2026-11-17-post-0.12/) (`corpus-work/run/` and `corpus-work/run-system1/`).  The
code was the same on both systems.  The Windows build is Proc-Spawner's commit 6c084cc (post-0.12: the work after
release 0.12).  Its `lib/`, `t/try.pl`, `win_spawn.h`, `win_loop.h` and `Spawner.xs` are those of the base run's code, commit
c5ec6a5, and commit fd17f98 for 4,060 snippets the base run ran again (`git diff` of these files between each of them
and 6c084cc shows no difference).

This was done in two ways.  One way is the module's own `posix_spawn` (on Windows the code of `win_spawn.h`).  The
other is Perl's own `system`, which the module uses where there is neither `posix_spawn` nor `fork` (the primitive
`system1`; a primitive is the module's lowest way of starting a program).  To make the module use it, both systems set, for this way, `PROC_SPAWNER_MISSING="posix_spawn fork"`, as the base run's
`run-system1/` did; with it, the module starts programs through the module Run (`Run.pm`), which does the
redirections there.

## Results, by what they say about Windows (2026-11-21)

The table of the next section counts each snippet with a different result under its first cause.  Regrouped by what
the result says about Windows, with Proc-Spawner's list of the snippets its Linux runs found to be chance or never
ending ([`large-subset-match.tsv`](https://github.com/ilyaz-ai/Proc-Spawner/blob/main/doc/large-subset/tools/large-subset-match.tsv)):
`tools/regroup.pl`, which writes `rows-WAY.tsv` (each snippet's row) and `regroup.txt` (the counts).  This table's are
in `tables/after-s1-portablegit/`; the files of those names directly in `tables/` and in `tables/after-s2-rerun/` are
earlier forms of it (below).  `regroup.pl` reads that list from Proc-Spawner (the file whose SHA-256 begins `a3dcb83b`,
on its `main` on 2026-11-22): the 58 snippets it takes from it are those whose column `why` in `rows-WAY.tsv` says
"project: chance" (45) or "project: never ends" (13).
Proc-Spawner's [`doc/pspawn-shell-windows.md`](https://github.com/ilyaz-ai/Proc-Spawner/blob/main/doc/pspawn-shell-windows.md#my-the-large-subset-under-wine),
"The large subset under Wine", explains each row.

| Snippets | posix_spawn | system1: its count + those of the posix_spawn row that are in (c) through system1 |
|---|---:|---:|
| The same result on Windows as on Linux | 39,837 | 39,484 + 353 = 39,837 |
| The same, apart from how paths are written | 357 | 348 + 9 = 357 |
| Says nothing: Linux itself gives no stable result | 131 | 131 |
| Differences made by the test setup, not by Windows: | [=6] | [=5 + 1 = 6] |
| &nbsp;&nbsp;(s1) both test runners stop a file at 20 MB; under Wine, a pipeline of Git for Windows' programs does not get there within the 5 seconds | 3 | 3 |
| &nbsp;&nbsp;(s2) on Linux, `PATH` holds the test runner's recorders, shell scripts, which `.` can read | 1 | 1 |
| &nbsp;&nbsp;(s3) environment variables the Windows runs had and the Linux runs did not¹ | 1 | 0 + 1 = 1 |
| &nbsp;&nbsp;(s4) under Wine, Git for Windows' programs cannot start a program with `fork` | 1 | 1 |
| Differences found on Windows: | [=79] | [=442] |
| &nbsp;&nbsp;(a) Windows behaves otherwise, and Proc::ShellSpawn passes that on | 50 | 46 + 4 = 50 |
| &nbsp;&nbsp;(b) Proc::ShellSpawn's own design for Windows² | 10 | 10 |
| &nbsp;&nbsp;(c) Perl's own `system` on Windows is at fault | 0 | 368 |
| &nbsp;&nbsp;(d) Git for Windows' `kill` and `comm` differ from Linux's | 18 | 17 + 1 = 18 |
| &nbsp;&nbsp;(e) a known bug of Proc::ShellSpawn (X71) | 1 | 1 |
| All snippets | 40,410 | 40,410 |

¹ The one snippet shows `ProgramFiles` and `ProgramW6432`: the Windows runs keep these two only to work around
X77, a known bug of Proc::ShellSpawn that is easy to fix; without them every start
of a program warns.

² The choices made when Proc::ShellSpawn was ported to Windows (Proc-Spawner's `doc/pspawn-shell-windows.md`, section
1): its `pwd` prints the directory as `Z:/...`; its builtin `umask` prints 0000; its `ulimit` is not supported (status
248); a command named `\` is the root directory (status 126, where Linux gives 127, not found); its `type` prints the
Windows file it found (`Z:\...\ls.EXE`).

X71, X77, X78 are Proc-Spawner's known issues (its `doc/pspawn-known-issues.md`).  X71, row (e): on Windows, `kill -s
WINCH $$` goes to the program `kill` instead of to Proc::ShellSpawn's own signal to itself.

(s1): both test runners limit each file a run writes to 20 MB (`prlimit --fsize`; `tools/runwine.pl` starts Wine
under it).  `yes 0 | sed '1~2s/0/1/'` and 2 snippets like it (`NB:4783`, `NB:4785`, `NB:683`) write without end.  On
Linux the limit stops them within about a second (status 153, SIGXFSZ).  Under Wine the same limit stops a Windows
program too: Git's `yes` alone, writing into a file, was stopped at 20,000,000 bytes after 0.17 seconds (status 153).
But through a pipe, Git's `yes 0 | sed '1~2s/0/1/'` passed 15.6 to 17.1 MB in 5 seconds (three runs, Wine 9.0,
PortableGit 2.47.1, one at a time, 2026-11-22), so with Git for Windows' programs (the rerun s1, below) they run out
of the 5 seconds first.  In the first records, with the Linux programs behind the stand-ins, they ended (`H-NOSTREAM`
in the next section): the stand-in of `yes` stops at a limit of its own.  The description of `H-NOFSIZE` in
`tools/classify.pl`, "the Windows test runner sets no limit on the size of output files", is wrong in that.

**Reading `rows-WAY.tsv`** (columns `id`, `row`, `rule`, `why`).  Only the snippets of the rows below are listed; a
snippet not listed is "the same", or "the same, apart from how paths are written" where its class in `cmp-WAY.tsv` (in
the same directory) is `same-paths`.

| `row` | The table's row |
|---|---|
| `M` | the same (Linux, run again where Windows ran, gave the Windows result: (M) of the next section) |
| `L` | says nothing (`why`: "project: chance", "project: never ends", "Linux runs differ") |
| `S1`, `S2`, `S3`, `S4` | (s1), (s2), (s3), (s4) |
| `OS` | (a) |
| `D` | (b) |
| `P` | (c) |
| `G` | (d) |
| `X` | (e) |
| `WV`, `U` | (no row: "varies on Windows only" and "not explained", none in this form; `WV` in the earlier forms) |

`rule` is the step or check of `cls-WAY.tsv` that gave the snippet its row (next section; the files of
`tables/after-s1-portablegit/`).  The rules each row is made of are listed in that directory's `regroup.txt`, under
"by row and rule"; what each rule means, in `tools/classify.pl` (its descriptions, `%MDESC` and the checks).  The
comments in `regroup.pl` letter some rows otherwise; the letters of this table are those above.

"Says nothing" takes, in both ways, every snippet known to vary on Linux, whatever its Windows result: the 45 the
project's runs found to be chance, the 13 that never end, and 73 more that gave more than one result in Linux runs of
one setup in any record kept (`tools/linux-varies.sh` writes `tables/after-s2-rerun/linux-varies.tsv` from the 4
Linux repeats per way made here and, in the base run's collection, `env/base` and `env/base2` and the repeats of 60
snippets of 2026-11-18; its second column names the group of runs in which the snippet varied: `g1` the repeats of
2026-11-18 in the usual way, `g2` `env/base` and `env/base2`, `h1` those through Run, `g3` and `h3` the 4 repeats
here, `posix_spawn` and `system1`): 45 + 13 + 73 = 131.  Most of rows (C) and (T) of the next section are there.  `tools/classify.pl`, from
2026-11-21, puts a snippet's hand-read verdict (for example `NB:3699` and `NB:5764` through system1: Perl's argument bug) before
every step of the next section's list but the file-size rule `H-NOFSIZE`.  The reruns s1 and s2 below, their files (`records-s1-portablegit.tar.xz`, `tables/after-s1-portablegit/`, `s1.ids`;
`records-s2-rerun.tar.xz`, `tables/after-s2-rerun/`, `s2.ids`), and the codes `S1`, `S2` in the rows files directly in
`tables/` and in `tables/after-s2-rerun/`, are named after an earlier form of this table, in which (s1) was "the Linux
programs behind the stand-ins" and (s2) "environment variables only the Windows runs had" (now (s3)); `s1.ids` (72
snippets) and `s2.ids` (15) are the snippets of those rows that ran again.  The rows files directly in `tables/`
count S1 76 / 74 and S2 8 / 7, those of `tables/after-s2-rerun/` S1 72 / 68 and S2 1 / 0 (`posix_spawn` /
`system1`).  Rerun s1: the 72 snippets of that first form of (s1) ran again on 2026-11-21
with Git for Windows' programs in place of the Linux ones, and with `USERNAME`, `TMP` and the like left out of the
runner's environment (`runwine.pl -noenv`) (`records-s1-portablegit.tar.xz`; `first/`, then `second/`,
the table's, where the stand-in of `kill` does not log its calls, as on Linux; `tools/rerun-s1pg.sh`,
`tools/compare-s1pg.sh`, `tables/after-s1-portablegit/`, whose `regroup.txt` has this table's counts).  PortableGit
2.47.1 (`tools/portablegit.txt`) unpacked; the stand-in (`tools/recorder.c`, built as `recorder-winreal.exe`) runs
its program from `usr\bin` when `WINREAL` names it (`runwine.pl -winreal`).  MSYS2's warning under Wine, worded as
Cygwin's ("Couldn't compute FAST_CWD pointer"), is taken out of the records by `tools/strip-fastcwd.pl` (the
originals are kept, `win-WAY-orig/`).  The comparison (`wincompare.pl`, `chance.pl`, `classify.pl`) now also takes
the program's own path off the start of a message on both sides, and quotes around an absolute path.  Rerun s2 (now row (s3)): `tools/runwine.pl` gave every Windows process the variables a Windows process usually has (`USERNAME`, `TMP`,
`COMPUTERNAME`, ...), and Wine adds its own (`WINEUNIXCP`, ...); the Linux runs have none of them.  The 15 snippets
that differed for that alone ran again on 2026-11-21 (`records-s2-rerun.tar.xz`), three times:
- `first/`: without `USERNAME` and `TMP` (`runwine.pl -noenv`): 6 the same.
- `second/`: also without `PATHEXT`, `PATH` written with `/`, Wine's variables hidden by `t/try.pl` (`TRY_HIDE`):
  still 6.  `PATH` came from the bridge's own `PATH`, and Wine gives its variables to the stand-ins again.
- `third/`: the runner gives only `SystemRoot`, `ProgramFiles`, `ProgramW6432` (without the last two,
  Proc-Spawner's known issue X77 made every start warn: a run between the second and the third, not kept) and `PATH`
  written with `/`; the bridge gives the Linux program neither Wine's variables nor `SystemRoot`
  (`runwine.pl -bridge-drop`), and `env` or `printenv` listing the environment the snippet's `PATH` as Git for
  Windows' programs show it (`-bridge-env-path`): 14 the same.
- `fourth/`, the table's: as the third, and the bridge leaves out `SystemDrive` too (Wine adds it): 14 the same; the
  one left shows `ProgramFiles` and `ProgramW6432`.  `tools/rerun-s2.sh` is this run;
  `tools/compare-s2.sh` compared it into `tables/after-s2-rerun/`; `tools/compare-s1pg.sh` then took the records of
  both reruns into `tables/after-s1-portablegit/`, whose `regroup.txt` has this table's counts.

What the rerun s2 means for 5 snippets.  They use `$USERNAME` or `$TMP` in the arguments of a program they call, and
the stand-in records the arguments.  On Linux the test runner sets neither variable.  On Windows both are always set,
by Windows itself, and `tools/runwine.pl` sets them as Windows does (`USERNAME=rcK`, `TMP` the run's directory).  So:

| Snippet | Linux | Windows, first records | Windows, rerun s2 |
|---|---|---|---|
| `NB:12016` `su -c "cd /home/$USERNAME/$PROJECT ; svn update" -m "$USERNAME"` | `su -c 'cd /home// ; svn update' -m ''` | `su -c 'cd /home/rc2/ ; svn update' -m rc2` | as Linux |
| `NB:4724` `groups $USERNAME \| cut -d\  -f 1` | `groups` | `groups rc3` | as Linux |
| `NB:7037` `rm -fR "${TMP}/";` | `rm -fR /` | `rm -fR Z:\runcompare\w0\run/` | as Linux |

(`NB:12017` and `NB:9171` are as `NB:12016`.)  The next section, made with the first records, counts these 5 in (W),
as Windows' own behaviour: "Windows sets `USERNAME`", "... Windows sets `TMP`".  This table takes the rerun s2, made
without the two variables, and counts them as the same.  On real Windows the variables are always there, so these
snippets would differ from Linux as in the first records.  Of the 15 snippets of the rerun s2, 14 count as the same
here, these 5 among them.  The repeats were not made again for the snippets of either rerun:
the steps that use them (3, 4 and 6 of the next section) use the repeats of the first setup.

"The same result" counts 15 and 13 snippets that are the same as the 4 Linux runs made here, though not as the base
run, made on another machine (row (M) below).  (a) here also takes `/usr/bin/find` and the like (rule `H-ELF`) and the
listings of the whole file system (`H-WINEFS`) from row (H) below.  The next section gives the first runs, before the reruns.

## Results by first cause

This table counts the first records, before the reruns s1 and s2 of the first section.  Its files are those directly in
`tables/` (`cmp-WAY.tsv`, `cls-WAY.tsv`, `summary.txt`), made on 2026-11-19 with the tools as they were then.  The
tools in `tools/` are those of 2026-11-21: they also take a program's own path off the start of a message and put the
hand-read verdicts first, so on the same records they give slightly other counts (checked for `posix_spawn`: same-paths
336 and messages only 14, where this table has 330 and 20).

In each way, the Windows result of a snippet was compared with its Linux result in the following:
- the exit status;
- the standard output;
- the error messages, compared as the project's runs compare them: Proc::ShellSpawn's prefix `sh: ` taken off the start
  of each line (with a number after it, if there is one: `sh: 1: `), and the characters sorted, so that messages whose
  lines interleave otherwise still count as equal;
- the programs called, with their arguments;
- the files left in the snippet's directory.

On Windows, every program a snippet calls is a small Windows program in its place, a stand-in, which records the call
(row (H) says why and how).  On Linux, the project's runs do the same with recorders, shell scripts on `PATH`.

| Snippets | posix_spawn | system1 |
|---|---:|---:|
| The same result on Windows as on Linux | 39,854 | 39,504 |
| A different result, by reason: | | |
| &nbsp;&nbsp;(W) Windows differs from Linux, and Proc::ShellSpawn follows Windows | 30 | 29 |
| &nbsp;&nbsp;(P) Perl's own `system` on Windows is at fault | 0 | 368 |
| &nbsp;&nbsp;(H) the test machinery under Wine, not Windows | 123 | 119 |
| &nbsp;&nbsp;(M) the base run's machine: its system files differ from those of the machine Windows ran on | 15 | 13 |
| &nbsp;&nbsp;(C) chance: the result changes from run to run | 41 | 39 |
| &nbsp;&nbsp;(T) runs out of the 5 seconds allowed | 17 | 16 |
| &nbsp;&nbsp;all different results (W + P + H + M + C + T) | 226 | 584 |
| The same, apart from how paths are written | 330 | 322 |
| All snippets | 40,410 | 40,410 |

The labels of this table are not those of the first section's: each is the first letter of the column `rule` of
`cls-WAY.tsv` (directly in `tables/`), which names the step or check that gave a snippet its row (`W-...`, `P-...`,
`H-...`), but (M), the rule `C-MACHINE`, (C), the rules `C-CHANCE` and `C-VARIES`, and (T), the rules `T-timeout-both`,
`T-timeout-win` and `T-timeout-linux`.

The row "the same, apart from how paths are written" is a third group, beside "the same" and the different results.
Each snippet is counted in exactly one row of a column, apart from the two total rows.  So, for `posix_spawn`,
39,854 + 226 + 330 = 40,410, and 30 + 0 + 123 + 15 + 41 + 17 = 226.  The rows (W) to (T) include the snippets whose
only difference is in the error messages: 20 of the 226 and 18 of the 584.

**How a snippet gets its row.**  The snippets with a different result were run 4 more times on each system, in each
way, on the machine Windows ran on, in the same environment.  In all, 588 snippets were repeated: every snippet with
a different result (rows (W) to (T), not the paths row) in at least one of four comparisons:
- `posix_spawn` on Windows against the base run;
- `system1` on Windows against the base run;
- `posix_spawn` against `system1`, both on Windows;
- `posix_spawn` against `system1`, both in the base run.

Each system and way thus has 5 runs of a repeated snippet.  On Linux these are the base run and the 4 repeats.  On
Windows they are the record the table uses (its "first run"; see "How the Windows runs were made") and the 4 repeats.
A snippet then gets the first row of the following steps that fits:

1. it ran out of time, on one system or both, in the first run (T);
2. the results are the same once paths are written alike (the row after "all different results"; below);
3. Linux, run again on the machine Windows ran on, gave the same result 4 times out of 4, which was not the base run's
   result, and one of the 5 Windows runs gave that result too (M);
4. one of the 5 Windows runs gave the same result as one of the 5 Linux runs (C);
5. one of a list of checks, each recognising one known cause of (W), (P) or (H), fits; they are tried in a fixed
   order and the first that fits counts (the list is in `tools/classify.pl`; it also names the snippets that no check
   recognised and that were given their cause by reading their results one by one);
6. the 5 runs on one system gave more than one result (C).  The 5 Linux runs include the base run, made on another
   machine; but every snippet that got here also gave more than one result among the runs made on the machine
   Windows ran on (the 4 Linux repeats, or the 5 Windows runs), so the other machine is not what puts it here.

No snippet was left without a row.  The files `cls-*.tsv` name, for each snippet with a different result, the step or
check that gave its row (column `rule`).  Where a later check of step 5 fits as well, they also name that check, as a
second reason (column `also`).

**The same, apart from how paths are written.**  On Windows, Proc::ShellSpawn shows directories in Windows' form.
`~` gives the value of `HOME`, which the test runner sets as `Z:\runcompare\w0\run\home`.  `pwd` gives Perl's form,
`Z:/runcompare/w0/run` (`w0` is the directory of worker 0; the test runner has 4 workers).  Linux shows `/runcompare/w0/run/home` and `/runcompare/w0/run` instead.  Windows accepts both
forms.  For these snippets, rewriting every such path (`Z:\x\y` and `Z:/x/y` as `/x/y`) left nothing else different:
they name the same directories as on Linux.  Where a path changes a result beyond how it is written, the snippet is in
one of the rows (W) to (T).  It is in (W) where the snippet works on the path itself (`pwd | cut -b2-`), and in (H)
where the path reaches one of the Linux programs behind the stand-ins.

**(W) Windows differs from Linux, and Proc::ShellSpawn follows Windows.**  The snippets were written for Linux.  On
Windows, some of what they use works otherwise, and the module does what Windows does.  This was seen under Wine, and
not checked on real Windows.  The causes, with their counts (`posix_spawn` / `system1`); the counts add up to the
row's:

| Cause | posix_spawn | system1 |
|---|---:|---:|
| A program name is found in any case: `PATCH` runs `patch.exe` | 5 | 5 |
| Windows sets `USERNAME` | 4 | 4 |
| `echo $PATH` shows the directories separated by `;` | 3 | 3 |
| `umask` is 0000 | 3 | 3 |
| `ulimit -n` and `ulimit -c` are not supported | 3 | 3 |
| `pwd | cut -b2-` cuts the first character off a Windows path (`Z:/...`) | 2 | 2 |
| A Windows path or name where Linux has its own: `type ls` gives `Z:\...\ls.EXE`; Windows sets `TMP` | 2 | 2 |
| `test -k /tmp` is false: Windows has no sticky bit | 2 | 2 |
| A file name ending in `nul` is the null device | 1 | 1 |
| A file name cannot hold `*` | 1 | 1 |
| `< dir`, a directory as input, fails | 1 | 1 |
| A command word `\` names the root directory: status 126, where Linux gives 127 (not found) | 1 | 1 |
| `LD_PRELOAD` does nothing: Windows has no `ld.so` | 1 | 1 |
| A command line holds at most 32,767 characters: `ldd /bin/* /usr/bin/*` gives "Argument list too long" (in `system1`, Perl reports it otherwise: (P)) | 1 | 0 |
| Total | 30 | 29 |

**(P) Perl's own `system` on Windows is at fault.**  Through `system1`, Proc::ShellSpawn starts programs with Perl's
own `system`.  On Windows, that has three faults that show here; the reports are in Proc-Spawner's
[`doc/perl-win32-system-bugs.md`](https://github.com/ilyaz-ai/Proc-Spawner/blob/main/doc/perl-win32-system-bugs.md).
- It hands a program its arguments as one command line, and does not quote some arguments so that the program
  splits the line back into the same arguments: those that hold `"`, are empty, or end in `\`.  So in
  `awk '{print $2 " " $1}'`, `awk` gets the words of its program as separate arguments (363 snippets; report 1).  By
  the author's decision, the module does not work around it.
- It passes a program only the descriptors 0, 1 and 2, so a redirection of descriptor 3 or above is refused (3
  snippets; not among the reports there).
- It reports every failure to start a program as "not found" (ENOENT).  So where `posix_spawn` reports a command line
  over 32,767 characters as "Argument list too long", `system1` reports "ldd: not found" (2 snippets; report 6).  These
  are the 2 `ldd /bin/* /usr/bin/*` snippets; in `posix_spawn`, one of them is in (W) and the other in (T).

363 + 3 + 2 = 368.

**(H) The test machinery under Wine.**  Wine cannot run a Linux program as the child of a Windows program properly:
it neither waits for it nor passes it its exit status or a pipe.  So on Windows every program a snippet calls is a
small Windows stand-in, which records the call.  The stand-ins of the programs that must really work (`cat`, `sed`,
`sort`, `ls`, `mkdir`, `yes`, ...) hand the work to the Linux program through files.  The program gets all its input
at once, before it starts, and its output is copied back after it has ended.  These differences come from the
stand-ins or from Wine, not from Proc::ShellSpawn or Windows.  What Windows programs would give in their place was
not tested.

| Cause | posix_spawn | system1 |
|---|---:|---:|
| A Windows path (of `~`, `$HOME`, `pwd`) reaches a Linux program behind a stand-in, which cannot use it: `mkdir ~/x` | 32 | 32 |
| `kill` of a process ID reaches the Linux `kill`, which does not know Windows process IDs | 19 | 19 |
| An absolute path to a Linux program (`/usr/bin/find`): Wine finds the file, which Windows cannot start (status 126; on real Windows, it would not exist) | 19 | 17 |
| The environment listed (`env`, `set`): it holds a variable that only the stand-ins need (beside Windows' own variables, as in (W)) | 15 | 14 |
| The whole file system listed (`find /`, `ls -lR /`): Wine's own files are there too | 12 | 12 |
| `wc` pads its counts otherwise when its input is a file, as behind a stand-in, than a pipe | 8 | 8 |
| `ls -l` of the snippet's directory: its parent, which the Windows runner makes, has another date and link count | 6 | 6 |
| Output without end (`yes`, `/dev/zero`, `tail -F`): a stand-in takes all of a program's input before the program starts, and passes its output on only after it ends, so nothing streams | 6 | 7 |
| `/dev/fd/3`, `/proc/self/fd`, `/dev/stderr`: they are the stand-in's own descriptors and files | 3 | 2 |
| A program ended by SIGPIPE on Linux: no signals reach it through a stand-in | 2 | 1 |
| `. script`: on Linux, `PATH` holds the recorder named `script`, a shell script, which `.` reads | 1 | 1 |
| Total | 123 | 119 |

**(M) The base run's machine.**  The base run was made in another container, on 2026-11-17, than the Windows runs and
the repeats.  The two containers' system files differ.  The one Windows ran in has MinGW and Wine installed (more
directories in `/usr`, more programs in `/usr/bin`), a newer Perl package (`5.38.2-3.2ubuntu0.7` against `...0.6`),
and more users and groups in `/etc/passwd` and `/etc/group`.  So snippets that read these files (`cat /etc/passwd`,
`ls /usr/bin`, `perl -V`, `find /usr/*`) give other results there than in the base run.  Linux, run again where
Windows ran, gave the Windows result: the difference is the machine's, not Windows'.  13 snippets are in (M) in both
ways; 2 only in `posix_spawn`.  One of them, `find /usr/*`, has the same result in `system1`; the other, an `awk`
program, is in (P) in `system1`.  (The base run's `system1` records were made a day later, 2026-11-18, in a
container that had MinGW too.)  One more snippet fitted step 3 in `system1`, but reading it showed a race between
two programs of the snippet: `sed s/.../ index.html | tee index.html`, where `sed` opens the file either before or
after `tee` empties it.  It was taken out of step 3 by hand (`tools/machine-not.ids`), and is in (C) in both ways.

**(C) Chance.**  The result of these snippets changes from run to run.  In `posix_spawn`, 4 snippets agree between
the systems in some run and 37 never agree but vary: 4 + 37 = 41.  In `system1`, 1 agrees in some run and 38 vary:
1 + 38 = 39.  What varies is mostly process IDs (`$$`, `ps`, `pstree`), the order of `sort -R` and of `xargs -P4`,
the times shown by `ls -l`, names such as `/tmp/x$$`, and races between the programs of a pipeline.  38 snippets are
in (C) in both ways.  3 are only in `posix_spawn`: in `system1`, 2 of them had the same result in the first runs, and
1 is in (H).  1 is only in `system1` (`seq 10 | xargs -P4 ...`).  The snippets with the same result in the first runs
were not repeated, so chance among them is not counted here.

**(T) Out of time.**  A snippet that does not end within 5 seconds is stopped.  The row counts the snippets that ran
out of time in the first run on either system; the repeats show which of them always do:
- 13, in each way, ran out of time in every run on both systems.  Most are endless loops (`while true`).
- 1, in each way, ran out of time in every run on Linux, but never on Windows: `yes | sed -n '200000000,...'`.  On
  Windows, the stand-in of `yes` is ended by a limit on the size of its output.
- The rest ran out of time in the first run only, and ended within the time in each of the 4 repeats.  They take
  about 3 seconds (for `ldd`, expanding `/bin/* /usr/bin/*` under Wine, before the "Argument list too long"), so they
  come near the limit when the machine is loaded.  In `posix_spawn` these are 3, all
  on Windows: `ls -lR /` (2) and `ldd /bin/* /usr/bin/*` (1).  In `system1` these are 2, both `ls -lR /`: one on
  Linux (in the base run), one on both systems.

13 + 1 + 3 = 17 and 13 + 1 + 2 = 16.

**Arguments that are not ASCII.**  The stand-ins used for the table read their arguments as bytes.  The 127 snippets with
text that is not ASCII were also run with stand-ins that read their arguments as Unicode, as most Windows programs
do.  With those, 114 (`posix_spawn`) and 113 (`system1`) of the 127 differ from Linux because of one more cause of
(W).  Proc::ShellSpawn passes a Perl byte string to Windows as text in the ANSI code page, which is 1252 under Wine.
So the UTF-8 bytes of `é` arrive as `Ã©` (`cls-*-wide.tsv`).  These are not counted in the table.  Of
the other 13 (`posix_spawn`) and 14 (`system1`), 7 are the same and the rest differ for causes of the table.  These runs used only part of the base run's
environment (only files' times fixed; see "How the Windows runs were made").

## How the Windows runs were made

- Windows: Wine 9.0 and Strawberry Perl 5.38.2.2, with the Windows build of Proc-Spawner (Strawberry's gcc).
- The test runner: `tools/runwine.pl`.  It runs the snippets as the project's
  [`large-subset-runcompare.pl`](https://github.com/ilyaz-ai/Proc-Spawner/blob/main/doc/large-subset/tools/large-subset-runcompare.pl)
  runs Proc::ShellSpawn, with the same fixture files, 5-second timeout, and up to 5 seconds for jobs left behind.  It
  has 4 workers; worker K has the directory `/runcompare/wK`, the user `rcK` and a Wine prefix of its own.  Its
  records have the same form as the project's.  Its pieces:
  - `tools/runner.c`: one Windows process per worker, which runs the snippets in job objects;
  - `tools/recorder.c`: the stand-ins;
  - `tools/bridge.sh`: what hands the work of a stand-in to a Linux program.
- The environment of step 3 below and of the repeats: the base run's `-env tmp,random,mtime`.  Each worker runs in a mount
  namespace of its own:
  - `/tmp`, `/var/tmp` and `/dev/shm` are emptied before every snippet (apart from Wine's own `/tmp/wine-*`);
  - the same fixed 1 MiB file is in place of `/dev/urandom` and `/dev/random`;
  - files' times are fixed.

  Each snippet ran on the worker it had in the base run (`-workers-from`, the runner's option that takes the
  workers from a run's records).  The other records were made with only files' times fixed, and with worker number = the snippet's position modulo
  4, which differs from the base run's worker for 2,478 snippets.
- The records of the Windows side were made in this order:
  1. All 40,410 snippets were run on 2026-11-18, in each way, with only files' times fixed (`win-WAY/`, WAY being
     `posix_spawn` or `system1`).
  2. The 127 snippets with text that is not ASCII were run again on 2026-11-19 (`win-WAY-na/`): until then, the
     runner wrote a snippet whose text has only Latin-1 characters to the file that Proc::ShellSpawn reads it from
     in Latin-1, not UTF-8.
  3. The 1,061 snippets whose result the rest of the environment, or the worker, can change were run again in the
     base run's full environment and workers (`base/win-WAY/`).  These are the snippets that differed from the base
     run in either way, and those whose text names `/tmp`, `/var/tmp`, `/dev/shm`, `/dev/random`, `/dev/urandom`,
     `$RANDOM`, `mktemp`, `shuf`, `sort -R` or `TMPDIR` (`rerun.ids`: `differ.ids` and `envtext.ids` together; 1,061
     of its 1,170 are among the 40,410, the rest are snippets outside the large subset, as the lists were made
     from all of the project's snippets; `differ.ids` has 759, `envtext.ids` 476, and 65 are in both: 759 + 476 - 65 = 1,170).  For the others, the result
     was the same as the base run's in both ways, and the text uses nothing the rest of the environment changes; a
     snippet whose result was the same on another worker does not depend on its worker.  In
     `posix_spawn`, a full run in that environment had been begun and stopped, so 5,825 more snippets had been run
     again in it; their records are used too (6,886 in all).

  Each step's records replace the earlier ones of the same snippet; the result is the table's "first run" on Windows.
- The repeats (`base/rep/`): 4 runs of each of the 588 snippets of `rep.ids`, on each system in each way, in the
  full environment and on the base run's workers.  Linux ran as in the base run, with dash and `bash --posix` beside
  Proc::ShellSpawn; only Proc::ShellSpawn's results are used here.
- The comparison: `tools/compare-base.sh` (`wincompare.pl`, `chance.pl`, `classify.pl`); the counts of this page:
  `tools/summary.pl`.

## Files

[`CONTENTS.txt`](CONTENTS.txt) lists every file; [`SHA256SUMS`](SHA256SUMS) has their checksums.
- `records.tar.xz`: the Windows records in the project's form (`run-K.jsonl`, one per worker K, one JSON line per
  snippet: the fields of [`../2026-11-17-post-0.12/README.md`](../2026-11-17-post-0.12/README.md), "The records",
  with the part `ours` only; on Windows `status` is a string, `"0"`, `"124"`, and `wtime` is the run's time in
  seconds, not compared; `wine.txt` saying how each was made, the logs): `win-WAY/`, `win-WAY-na/`, `win-WAY-wide/` (the stand-ins that read Unicode), `base/win-WAY/`; the repeats of
  both systems, `base/rep/{linux,win}-WAY-r2/` to `-r5/` (the first run being the base run on Linux, the first
  record on Windows).
- `tables/`: the comparisons and their summaries, `cmp-*.tsv` and `cmp-*.txt`; the rows, `cls-*.tsv` and `cls-*.txt`;
  the repeats' results, `chance-*.tsv`; `machine-WAY.ids`, the snippets of (M); the snippet lists `rep.ids`,
  `rerun.ids`, `differ.ids` and `envtext.ids`; `summary.txt`; and `variability.tsv`.
- `variability.tsv` (in `tables/`): for each repeated snippet and kind of run, the runs made on the machine Windows ran
  on, in the same environment, and the number of different results among them.  The kind of run is the system and
  the way, with Proc::ShellSpawn.  The runs are 4 on Linux and 5 on Windows; the base run is left out, being of
  another machine.  It is the form proposed for the project's record of what varies by chance (Proc-Spawner's `TODO`,
  part B, "Chance from every run").  On Linux 45 (`posix_spawn`) and 44 (`system1`) of the 588 vary; on Windows 51
  and 50.  These are not counts of (C): they cover all 588 snippets, whatever their row, and leave out the base run.
- `tables/after-s1-portablegit/rows-WAY.tsv` and `regroup.txt`: the first section's table; the files of the same
  names directly in `tables/` and in `tables/after-s2-rerun/`: earlier forms of it (the codes `S1`, `S2` of that form,
  first section).  The two `after-*` directories also hold the comparisons (`cmp-*`, `cls-*`) with the reruns' records
  in place of the first ones; they used the chance files and `machine-WAY.ids` of `tables/` (not made again, and not copied there).
  `tables/after-s2-rerun/` was made with the tools before their change of 2026-11-21 (its `cmp-*` have
  same-paths 330, as `tables/`); `tables/after-s1-portablegit/` with the kept ones, which make it again from the first
  records, the rerun s2's `fourth/` ("s2d" in `compare-s1pg.sh`) and the rerun s1's `second/`.
- The columns of `cls-WAY.tsv`: `id`; `class`, the comparison's (`differs`; `msg`, only the messages differ;
  `timeout-both`, `timeout-win`, `timeout-linux`); `rule`, the step or check that gave the row; `parts`, the parts that
  differ (`status`, `out`, `err`, `rec`, `files`, `after`); `noisy`, the word `noisy` where the base run's two ways
  differ from each other on Linux (`wincompare.pl -noise`); `also`, the later checks that fit too; `text`, the start of the snippet.
  `cmp-WAY.tsv` (its header line starts with `# `): every snippet whose result is not `same`: id, class (also
  `same-paths`), the parts that differ, `noisy`, the start of the text, then for each part that differs `PART: L=...`
  and `PART: W=...` (Linux, Windows; `err` as recorded, the rest normalised; cut to 400 characters; `\x1f` shown as `|`,
  `\x1e` as `^`).  In `*-win-ways` and `*-linux-ways`, L is `posix_spawn` and W `system1`.  `summary.txt` letters
  the second section's rows `a` to `f`: `a` = (W), `b` = (P), `c` = (H), `d` = (M), `e` = (C), `f` = (T).
- `chance-WAY.tsv`: for each snippet, the runs and the distinct results on Linux (`runs_a`, `distinct_a`: the base run
  and the 4 repeats) and on Windows (`runs_b`, `distinct_b`: the first run and the 4 repeats), and `overlap`, 1 when
  some run of each side agree once paths are written alike; 1 run a side for the snippets not repeated.
  `chance-here-WAY.tsv`: the same with the 4 Linux repeats alone; `chance-linux-base-WAY.tsv`: the base run against
  the 4 Linux repeats (for (M)).  `cmp-win-ways.*`, `cls-win-ways.*`, `chance-win-ways.tsv`: the two ways against each
  other on Windows; `cmp-linux-ways.*`, `chance-linux-ways.tsv`: on Linux.  `*-wide.*`: the stand-ins that read
  Unicode (the section on arguments that are not ASCII).  `saved-WAY.*`: the first records alone (steps 1 and 2 of
  "How the Windows runs were made") against the base run.
- `tools/compare-base.sh` makes the files directly in `tables/`, `tools/compare-s2.sh` and `tools/compare-s1pg.sh`
  those of the `after-*` directories; `tools/pipeline9.sh` ran step 3 of "How the Windows runs were made";
  `tools/fork-test/`: the check behind (s4), MSYS2's `fork` under Wine; `tools/append-test/`: the check that appending
  to a file under Wine 9.0 is not atomic between processes (X78; one stand-in log lost a line so).
- `tools/`: the runner and the comparison scripts, with the stand-ins and the runner built for Windows (`*.exe`; built
  with `x86_64-w64-mingw32-gcc -O2`).
- `superseded.tar.xz`: see the footnote.

Footnote.  A first comparison (2026-11-18) used Linux runs made in the Windows runs' own container, with only files'
times fixed, as on Windows then.  That compares Proc::ShellSpawn on Windows with a Linux run limited in the same way,
not with the base run.  Its records and tables are kept in `superseded.tar.xz`: they show what Proc::ShellSpawn gives
on Linux in that limited environment, which `large-subset-runcompare.pl -env mtime -base /runcompare` makes.
