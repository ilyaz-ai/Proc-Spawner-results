# Proc-Spawner-results

Large records of measurements made for the CPAN distribution
[Proc-Spawner](https://github.com/ilyaz-ai/Proc-Spawner), kept here so that the distribution's
repository stays small.  The distribution's documents and reports are derived from these records;
the records themselves are not shipped.

Layout: `PROJECT/DATE-LABEL/`, one directory per collection, named by the date of the
measurement and the code label it was measured on (labels as in Proc-Spawner's `doc/README.md`,
"Version labels of the results").  Each collection has a `README.md` (what it is, what made it,
how to use it), `CONTENTS.txt` and `SHA256SUMS`.

The records of every collection have one form, one JSON line per snippet, described with the rules by
which Proc-Spawner's reports compare them in
[`proc-spawner/2026-11-17-post-0.12/README.md`](proc-spawner/2026-11-17-post-0.12/README.md) ("The
records", "How the reports compare the shells").  The tools that made and read them are in
Proc-Spawner, `doc/large-subset/tools/`, apart from those of the Wine collection, which it holds itself;
each README names what of Proc-Spawner a reader needs besides.

| Collection | What |
|---|---|
| [`proc-spawner/2026-11-17-post-0.12/`](proc-spawner/2026-11-17-post-0.12/) | the corpus runs of `make corpus-all` (2026-11-17) and the runs of 2026-11-18 made on them: Proc-Spawner's `corpus-work/` without the corpora |
| [`proc-spawner/2026-11-19-post-0.12-wine/`](proc-spawner/2026-11-19-post-0.12-wine/) | Proc::ShellSpawn on Windows (under Wine), both ways (`posix_spawn`, `system1`), compared with the base run of `2026-11-17-post-0.12/`: the records, the tables, the tools and the results (runs of 2026-11-18/19) |
| [`proc-spawner/2026-11-21-post-0.13-ours-alone-provisional/`](proc-spawner/2026-11-21-post-0.13-ours-alone-provisional/) | **provisional, replaced** by `2026-11-22-post-0.13/`: Proc::ShellSpawn alone over the snippets of the runs of 2026-11-17, with 0.13's code and with post-0.13's (2026-11-20 and 21), and what changed |
| [`proc-spawner/2026-11-22-post-0.13/`](proc-spawner/2026-11-22-post-0.13/) | the corpus runs of `make corpus-all` (2026-11-22; post-0.13 with X80, D3, X81), reported again with the tools after X82: Proc-Spawner's `corpus-work/` without the corpora |
| [`proc-spawner/2026-11-26-post-0.13-rejected/`](proc-spawner/2026-11-26-post-0.13-rejected/) | the 1,543 snippets the large parser rejects, run in dash and bash alone (`make corpus-rejected`, 2026-11-26), on the snippets of `2026-11-22-post-0.13/` |
| [`proc-spawner/2026-11-26-post-0.13-rejected-envs/`](proc-spawner/2026-11-26-post-0.13-rejected-envs/) | the work list's candidates among those, again in example environments made by reading them (`make corpus-rejected-envs`, 2026-11-26) |

## What is not here, and where it is

The collections hold the runs: each snippet's text and what dash, `bash --posix` and Proc::ShellSpawn did with it, in
each environment it ran in.  They do not hold what decided which environments a snippet gets, what the runs started
with, or what was concluded from them.  Those are files of the CPAN distribution Proc-Spawner
(<https://metacpan.org/dist/Proc-Spawner>), release 0.13 or later (the last two rows: after 0.13); the paths are inside
it.

| Missing here | In the distribution |
|---|---|
| What each run started with: the files of the run's directory and their contents (the fixture), the variables, the directory `quiet` first on `PATH` (the real `echo`, `printf`, `test`, `[`, `true`, `false`, `pwd`, `kill`, not logged), the recorders that stand in for the other programs and what they log, the shell's standard input, `$0` and a setup's arguments, the time and size limits, what each key of a setup does (`env`, `files`, `args`, `stdin`, `standin`) | `doc/large-subset/tools/large-subset-runcompare.pl`, the runner (its header says what each part does) |
| The program names the runs see: a recorder for each; every other name is "not found" | `doc/large-subset/tools/large-subset-programs.txt` |
| What the levels and the codes in `levels.tsv` mean (`program`, `pid`, `listing`, `passthrough`, ...) | `doc/large-subset/large-subset-environment.md`, sections 1 to 3; step 2: section 10; step 3: section 12 |
| Step 3's class of each undecided snippet (pass, split, control, affects-shell) | `doc/large-subset/tools/large-subset-step3.tsv`; the 93 that Claude (an AI) classified by reading them: `large-subset-ai-classes.tsv` |
| Which snippets were decided to be chance (a result that varies from run to run), and each snippet's verdict over all its environments | `doc/large-subset/tools/large-subset-match.tsv` (column 7 `chance`; column 9 stable or unstable) and the rulings it applies, `large-subset-match-known.tsv`.  A collection's `match/match0.tsv` is a first pass of the match, not its result |
| The tools that decide, from a snippet's text, which environments it runs in | `doc/corpus.mk` (`make corpus-help`): `large-subset-blocks.pl -d` (what a snippet depends on), `large-subset-setups.pl` (the setups of steps 2 and 3), `large-subset-ids.pl` (the snippets of each environment variant, by code), `large-subset-bgjobs.pl` (the snippets with a background job) |
| The reports and records made again from a collection's runs, without running a shell | `make corpus-rereport` (after 0.13) |
| Which collection, and which code, made each of the distribution's records | `doc/large-subset/tools/large-subset-tables-used.tsv` (after 0.13) |

Checked on 2026-11-23 with the collection `2026-11-22-post-0.13`: from the snippets' texts these tools give, byte for
byte, the environments its runs used (the setups of steps 2 and 3 and which snippets got them, the snippets of each
environment variant, the 44 with a background job), and `make corpus-rereport` gives the 43 chance snippets of
`large-subset-match.tsv`.  38 of the 43 are chance by their own codes (`pid`, `listing`, `time`, `random`,
`path-proc`, `path-root`), which come from the text; 5 by rulings of `large-subset-match-known.tsv`, and for 4 of
those the runs the ruling cites (200 and 50 runs by hand, 10 runs, and 20 runs of a race step made before these
collections) are in no collection.

## The snippets the parser rejects: dash and bash only

The corpus runs take only the snippets that Proc-Spawner's large parser accepts (`samples.tsv`, column `large` 1:
40,409 in the collection of 2026-11-22).  The other 1,543 (column `large` 0: tldr 209, NL2Bash 581, ShellCheck's
tests 624, the cookbook 55, pure-bash-bible 73, pure-sh-bible 1) cannot be run by Proc::ShellSpawn, which refuses them.
Why the parser refuses each is in `samples.tsv`, column `why`; the most frequent reasons: `unsupported` 323, `builtin`
241, `keyword` 199, `process` 178, `unexpected` 128, `bash-only` 77.

They ran once in dash and in bash alone on 2026-11-26, in the environment of the base run:
[`proc-spawner/2026-11-26-post-0.13-rejected/`](proc-spawner/2026-11-26-post-0.13-rejected/) (Proc-Spawner's `make
corpus-rejected`, 2½ minutes).  A try of 2026-11-23 had stopped at 1,196 of them: bash's `suspend -f` stops its own
process group, and with it the runner's `timeout` (Proc-Spawner's known issue X85, fixed).  Which further environments
each one needs cannot come from Proc-Spawner's tools, which work on the parse tree: it would be decided by reading
them, as for the 93 of `large-subset-ai-classes.tsv`.
