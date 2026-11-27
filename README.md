# Proc-Spawner-results

The records of the measurements made for the CPAN distribution
[Proc-Spawner](https://metacpan.org/dist/Proc-Spawner), kept here because they are too large for the distribution.
The distribution's documents and its smaller records are made from them.

## Possible bugs of dash and bash

Comparing dash and bash on these snippets turned up places where one of them seems to contradict POSIX, its own
manual, or itself.  Each report gives, for every case, a command to paste, what each shell prints, the rule quoted,
the snippets that showed it, and whether the latest version still has it:

- [`upstream-reports-dash.md`](upstream-reports-dash.md): 11 cases, all still in dash 0.5.13.6, the latest release
  (one of them only in part);
- [`upstream-reports-bash.md`](upstream-reports-bash.md): 5 cases still in bash 5.3.20, the latest release, and in
  its development version, and 2 more fixed in 5.3.

## What was measured

Proc-Spawner's module **Proc::ShellSpawn** (*ShellSpawn* below) runs a string of shell text itself, without starting
`/bin/sh`.  It runs only the part of the shell language that its parser (Proc::ShellSubset::Large, *the large
parser*) accepts.  The measurements ask how close ShellSpawn comes to real shells:

- **The snippets** (*the corpus*): 41,952 pieces of shell text taken from six public collections: the tldr pages
  (short examples of commands, `TL:`), NL2Bash (a data set pairing English requests with bash commands, `NB:`),
  ShellCheck's test cases (`SC:`), the pure bash bible and the pure sh bible (collections of idioms, `PB:`, `PS:`) and
  the examples of the bash Cookbook (`BC:`); the prefix starts each snippet's id.  The texts are in the collections'
  `samples.jsonl`; the sources themselves are not here (`make corpora`, in the distribution's directory, fetches them
  at pinned commits; every `make` below runs there).
- **A run**: one snippet run once by one shell, in a fresh copy of a small directory, as an unprivileged user, without
  network, for at most 5 seconds.  The shells are dash 0.5.12 (`dash -c TEXT`), bash 5.2.21 in its POSIX mode (`bash
  --posix -c TEXT`; ShellSpawn aims at the POSIX shell language) and ShellSpawn (on Ubuntu 24.04, Perl 5.38.2).  `echo`, `printf`, `test`, `[`, `true`, `false`, `pwd` and `kill`
  run as themselves; every other program a snippet calls is replaced by a *recorder* that logs its arguments, and then
  runs the real program if it only reads or prints (`cat`, `grep`, ...), else prints nothing.  So every shell meets
  the same files and programs, and only the shells differ.  A run's record holds the exit status, the standard
  output and error, the files left in the directory, and the programs called.
- **The environments**: every snippet runs in one standard environment, *the base run*.  Snippets whose result can
  depend on what they find (files, variables, input, arguments) run again in *example environments* made for them.
- **The comparison**: for each snippet, whether ShellSpawn does what dash and bash do, in every environment it ran in.
  What the counts mean for the module is in the distribution's `README.md`, "How close to dash and bash".

## The collections

One directory per collection, `proc-spawner/DATE-LABEL/`: the date of the runs, and the label of the version of
Proc-Spawner's code they used (a release, such as `0.12`, or the work after it, such as `post-0.12`).  Each has a
`README.md` (what it holds, what made it, how to use it), `SHA256SUMS`, an archive of the records, and most also a
`CONTENTS.txt` (the archive's parts).  An archive named `corpus-work.tar.xz` is the directory `corpus-work/` in which
Proc-Spawner's `make corpus-all` makes the runs and the reports, without the sources.

| Collection | What |
|---|---|
| [`proc-spawner/2026-11-22-post-0.13/`](proc-spawner/2026-11-22-post-0.13/) | **The current one**: every snippet the large parser of post-0.13 accepts (40,409), in dash, bash and ShellSpawn, in every environment; the records behind the distribution's documents |
| [`proc-spawner/2026-11-17-post-0.12/`](proc-spawner/2026-11-17-post-0.12/) | The same with the code of post-0.12, whose parser accepts one snippet more (40,410: `exec command -with -flags`); also runs of 2026-11-18 on the same snippets: ShellSpawn starting programs through the module Run, and repeats |
| [`proc-spawner/2026-11-21-post-0.13-ours-alone-provisional/`](proc-spawner/2026-11-21-post-0.13-ours-alone-provisional/) | **Provisional, replaced** by `2026-11-22-post-0.13/`: ShellSpawn alone (`ours`, in the name, is the records' name for ShellSpawn), with newer code, compared with dash's and bash's runs of `2026-11-17-post-0.12/` |
| [`proc-spawner/2026-11-19-post-0.12-wine/`](proc-spawner/2026-11-19-post-0.12-wine/) | ShellSpawn on Windows (Strawberry Perl under Wine), with each of the two ways the distribution can start a program there (`posix_spawn`: its own, on Windows the code of `win_spawn.h`; `system1`: Perl's `system`, through the module Run), compared with the base run of `2026-11-17-post-0.12/`; with its own tools and tables |
| [`proc-spawner/2026-11-26-post-0.13-rejected/`](proc-spawner/2026-11-26-post-0.13-rejected/) | The 1,543 snippets the large parser rejects, in dash and bash alone (below) |
| [`proc-spawner/2026-11-26-post-0.13-rejected-envs/`](proc-spawner/2026-11-26-post-0.13-rejected-envs/) | 25 of those, in dash and bash again, in example environments (below) |

The records of every collection have one form, one JSON line per snippet;
[`proc-spawner/2026-11-17-post-0.12/README.md`](proc-spawner/2026-11-17-post-0.12/README.md) describes it ("The
records") and how the distribution's reports compare the shells ("How the reports compare the shells").  The tools
that made and read the records are in the distribution, `doc/large-subset/tools/`, apart from those of the Wine
collection, which holds its own.

## What is not here, and where it is

The collections hold the runs.  They do not hold what decided which environments a snippet gets, what each run started
with, or what was concluded from the runs.  Those are files of the distribution
(<https://metacpan.org/dist/Proc-Spawner>, release 0.13 or later; for the last two rows of the table below, 0.14 or
later); the paths are relative to the distribution's directory.

| Missing here | In the distribution |
|---|---|
| What each run started with: the files of its directory, the variables, the programs on `PATH` and the recorders, the standard input, the arguments, the limits; what each key of an example environment does (`env`, `files`, `args`, `stdin`, `standin`) | `doc/large-subset/tools/large-subset-runcompare.pl`, the program that makes the runs (its header) |
| The program names the runs see (a recorder for each; every other name is "not found") | `doc/large-subset/tools/large-subset-programs.txt` |
| How the distribution sorts the snippets by what can change their result (its *levels*, and the *codes* in a collection's `levels.tsv`: `program`, `pid`, `listing`, `passthrough`, ...) | `doc/large-subset/large-subset-environment.md`, sections 1 to 3; the example environments: sections 10 and 12 |
| For each snippet whose result depends on its environment, where the values it takes from there end up (classes pass, split, control, affects-shell) | `doc/large-subset/tools/large-subset-step3.tsv`; the 93 that the tools could not class, classified by Claude (an AI) reading them: `large-subset-ai-classes.tsv` |
| Which snippets give results that vary from run to run (*chance*), and each snippet's verdict over all its environments | `doc/large-subset/tools/large-subset-match.tsv` (column 7 `chance`; column 9 stable or unstable) and the author's rulings on which differences are accepted, `large-subset-match-known.tsv`.  A collection's `match/match0.tsv` is a first pass, not the result |
| The tools that decide, from a snippet's text, which environments it runs in | `doc/corpus.mk` (`make corpus-help`): `large-subset-blocks.pl -d` (what a snippet depends on), `large-subset-setups.pl` (the example environments), `large-subset-ids.pl` (the snippets of each change of the base environment), `large-subset-bgjobs.pl` (the snippets that leave a job running in the background) |
| The reports and records made again from a collection's runs, without running a shell | `make corpus-rereport` |
| Which collection, and which version of the code, made each of the distribution's records | `doc/large-subset/tools/large-subset-tables-used.tsv` |

Checked on 2026-11-23 with `2026-11-22-post-0.13/`: from the snippets' texts alone, these tools gave exactly the
environments its runs used (the example environments and which snippets got them, the snippets of each change of the
base environment, the 44 with a background job), and `make corpus-rereport` gave the 43 chance snippets of
`large-subset-match.tsv`.  38 of the 43 are chance by what their text does (it prints process IDs, lists
directories, reads the time or random data, or looks into `/proc` or `/`: codes `pid`, `listing`, `time`, `random`,
`path-proc`, `path-root`); 5 by rulings of `large-subset-match-known.tsv`.  For 4 of those 5 rulings, the runs that
each cites are in no collection (200 runs and 50 runs made by hand, 10 runs, and 20 runs of a race).

## The snippets the parser rejects: dash and bash only

Since ShellSpawn runs only what the large parser accepts, the collections above hold only those snippets: 40,409 of
the 41,952 (`samples.tsv`, column `large` 1, in `2026-11-22-post-0.13/`).  The other 1,543 (`large` 0: tldr 209,
NL2Bash 581, ShellCheck's tests 624, the bash Cookbook 55, the pure bash bible 73, the pure sh bible 1) were run in
dash and bash alone: each once, in the environment of the base run,
[`proc-spawner/2026-11-26-post-0.13-rejected/`](proc-spawner/2026-11-26-post-0.13-rejected/).  Why the parser rejects
each is in `samples.tsv`, column `why`; the most frequent reasons: `unsupported` 323, `builtin` 241, `keyword` 199,
`process` 178, `unexpected` 128, `bash-only` 77, others 397.

Which example environments a rejected snippet needs cannot come from the distribution's tools, which read the parse
tree.  So they were written by reading the snippets, for the 34 that the distribution's *work list* names as
candidates: snippets that use only features in which dash and bash agree (judged from the text), and that no decision
of the author keeps rejected.  25 of the 34 read something from their environment and ran again, in dash and bash, in
the environments written for them:
[`proc-spawner/2026-11-26-post-0.13-rejected-envs/`](proc-spawner/2026-11-26-post-0.13-rejected-envs/).  The other
1,518 rejected snippets, including the other 9 candidates, ran in the base environment only.  What came out, and
whether the parser should accept the candidates: the distribution's `README.md`, "The rejected snippets".  Where
dash or bash themselves seem to be wrong: "Possible bugs of dash and bash", above.
