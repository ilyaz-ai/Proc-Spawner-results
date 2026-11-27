# Proc-Spawner's corpus runs of 2026-11-22 (code label post-0.13)

`corpus-work.tar.xz` (7.6 MB; 338 MB unpacked, 1,254 files) is the directory `corpus-work/` of the session that
made the runs, as it stood on 2026-11-22 at 10:56 UTC, without `corpora/` (the pinned sources, which
`make corpora` in Proc-Spawner fetches again) and without `builtins-run.jsonl` (below).  `CONTENTS.txt` lists its
parts with sizes and the time of each part's newest file (UTC).

These are the records behind the corpus counts of Proc-Spawner's documents since 2026-11-22: its `README.md`, "How
close to dash and bash"; `doc/large-subset/large-subset-state.md`, sections 3 and 7;
`doc/large-subset/large-subset-environment.md`, sections 1 to 3 and 9 to 12; `doc/large-subset/large-subset-match-raw.md`.
They replace, for those documents, the collection [`../2026-11-17-post-0.12/`](../2026-11-17-post-0.12/) and the
provisional [`../2026-11-21-post-0.13-ours-alone-provisional/`](../2026-11-21-post-0.13-ours-alone-provisional/).

The records have the form, and the reports compare them by the rules, that the README of
[`../2026-11-17-post-0.12/`](../2026-11-17-post-0.12/README.md) describes ("The records", "How the reports compare the
shells"); what it says of the three shells, the isolation of each run, the recorders and the environments holds here
too, and so does what it says of the names: these records keep the key `ours`, these reports the class `OURS`; Proc-Spawner's
records made from them since 2026-11-23 say `shellspawn` and `SHELLSPAWN` (its decision D5).  This file says what is particular to this collection.  What a reader of this repository alone is missing, and
where it is, and the snippets the parser rejects (run in dash and bash alone since 2026-11-26): the repository's [`README.md`](../../README.md).

## What made it

- **The runs**: `make corpus-all` on Proc-Spawner's branch `corpus-run-2026-11-22`, at commit `f781213` (the code of
  `main` then: post-0.13 with X80 fixed, decision D3 and X81 fixed), from an empty `corpus-work/` (`make
  corpus-clean`), as root, 4 workers, the spawn primitive as built (posix_spawn).  The parse results came from the
  stored scan (`OLDSCAN=`, `SCCACHE=`: reparsed, not rescanned).  Started 01:31:54 UTC, ended 05:11:15 UTC with
  status 0: `all.log` is that run's output (its last line `ALL DONE rc=0`), `heartbeat.txt` the machine's uptime every
  30 seconds meanwhile, `run.sh` the script that started it.  No step was run twice or resumed.
- **The reports, made again** (10:13 to 10:19 UTC): the run's tools had X82 (Proc-Spawner's known issue: taking dash's
  and bash's prefix off the messages also took a word glued before it), which Proc-Spawner's `main` had fixed
  meanwhile.  So every report and record was made again from these runs with the tools of `main` at commit
  `e5a7c17`, by `rereport.sh` (the report commands of Proc-Spawner's `doc/corpus.mk`, without any run): `runreport*.txt`,
  `builtins.txt` and `builtins.jsonl` (with `-reuse`: the answers the run stored, the classes computed again),
  `env/cmp-*.txt`, `step3/match.txt`, `step3-affects-shell/match.txt` and `match.tsv`, `races/repeat.txt`,
  `endmodes/repeat.txt`, `match.txt`, `match-raw.txt`, `levels.txt` and `blocks.jsonl`, `levels.tsv`.  The
  reports as the run's own tools made them are in `reports-before-x82/`.  `builtins-run.jsonl`, the builtins'
  database as the run wrote it, is left out: its answers are those of `builtins.jsonl`, only its classes and
  wording differ.
- **Kept as the run made them**: the per-sample records (`run/`, `q/`, `env/` but its `cmp-*.txt`, `step2/`,
  `step3/`, `step3-affects-shell/`, `match/`, `endmodes/`), and the reports of the three-way comparison
  (`threeway.txt`, `match/threeway.txt`, `step3/threeway.txt`, `step3-affects-shell/threeway.txt`), whose tool X82 did
  not touch.

The records derived from these runs are in Proc-Spawner, `doc/large-subset/tools/` (on `main` since commit
`e5a7c17`): `large-subset-run-differences.tsv`, `-builtins-differences.tsv`, `-env-variants.tsv`, `-env-setups.tsv`,
`-env-control.tsv`, `-env-affects-shell.tsv`, `-endmodes.tsv`, `-env-races.tsv`, `-match.tsv`, and
`doc/large-subset/large-subset-provenance.tsv`.  The three-way comparison's records are there too:
`large-subset-threeway-db.jsonl` (each call of `echo`, `printf`, `test`, `[`, `pwd` and `kill` that ShellSpawn made
in the base run, with the answers of dash's builtin, bash's builtin and the program) and
`large-subset-threeway-differences.tsv` (the calls where the three do not agree); for the match,
`large-subset-match-calls.jsonl`, `large-subset-env-control-calls.jsonl` and `large-subset-env-affects-shell-calls.jsonl`
(the calls of the snippets where ShellSpawn is not as both shells, with ShellSpawn's own answer too).  Those five
were written by the run (Proc-Spawner commits `aafe5df` and `715edf0`) and are kept as it wrote them.

Which runs and which code made each of Proc-Spawner's 21 records of the corpus runs is its file
`doc/large-subset/tools/large-subset-tables-used.tsv` (since Proc-Spawner commit `ff5af06`; shipped in its distribution,
checked by its `t/records.t` in every `make test`).  For the 18 of them that come from this collection, it names this
collection, the SHA-256 of `corpus-work.tar.xz` (as in `SHA256SUMS`), and each record's SHA-256; the other 3 come
from the two `2026-11-26-…` collections.  The 11 records the reports write were made again from this collection
with Proc-Spawner's `make corpus-rereport` (commit `b0f34de`): 10 came out byte for byte the same, and
`large-subset-endmodes.tsv` had the same rows in another order (Proc-Spawner's known issue X83, fixed there).

## What was run

- **The snippets**: the 40,409 that Proc-Spawner's large parser accepts since post-0.13: the rows of `samples.tsv`
  whose column `large` is 1 (one fewer than on 2026-11-17: `TL:common/exec.md:8`, `exec command -with -flags`, which
  every grammar refuses since Proc-Spawner's decision D1).  `TL:` tldr 29,231, `NB:` NL2Bash 10,039, `SC:`
  ShellCheck's tests 1,021, `PB:` 49, `PS:` 43, `BC:` 26.
- **The steps of `make corpus-all`**, each as in the collection of 2026-11-17: the base run (`run/`) and its logging
  run (`q/`); the builtins alone (`builtins.jsonl`); the environment varied (`env/`); step 2 (`step2/`); step 3,
  control (`step3/`) and affects-shell (`step3-affects-shell/`); the end modes of K5 (`endmodes/`); the match's
  logging runs (`match/`).  The races (`races/`): no snippet was called chance by the code `race`, so nothing ran 20 times and the record `large-subset-env-races.tsv` stays empty, as it has been since Proc-Spawner's commit `bc2b923`.
- Not in this collection, unlike that of 2026-11-17: runs through Run (`system1`) and repeats by hand.

## The counts, in short

The match over every environment: 38,594 snippets alike in every environment; 1,802 where ShellSpawn is not as both
shells (legalized by rulings 1,633, awaiting decision A12 88, chance 43, not legalized 38); 13 timeouts;
38,594 + 1,802 + 13 = 40,409 (`match.txt`).  The base run alone: ShellSpawn differs where dash and bash agree in 2
snippets (`printf -v`), known chance 1, messages worded as neither 55 (`runreport.txt`).  What each count means, and
every change against 2026-11-17 traced snippet by snippet: Proc-Spawner's documents above and its `Changes`, under
post-0.13.

## What varies from run to run

Two runs of dash and bash in one environment exist for 10,464 of the 40,409 snippets (a snippet may be in several
families).  Between the two runs, compared by status, standard output without message lines, calls sorted and files
without message lines, dash or bash differs in 131 snippets: step 2 (`step2/base` and `base2`, 2,901 snippets) 2,
`NB:10133` and `NB:12196`; step 3's control (`step3/`, 2,474) the same 2; step 3's affects-shell (1,034) 15; the
environment varied, `env/base` and `base2` (7,003) 93, `env/sbase` and `sbase2` (1,248) 50.  The runs of `env/` had
neither the fixed `/tmp` nor the fixed random source and file times of the other families (`-env tmp,random,mtime`),
so more varies there.  The counts in the README of 2026-11-17 ("What varies from run to run") are of its own runs, not
of these.  For the other snippets there is one run of each shell; which snippets Proc-Spawner decided to be chance is
its `large-subset-match.tsv` (the repository's [`README.md`](../../README.md), "What is not here").

## Checked

- 2026-11-22, after packing: the archive unpacked into an empty directory, and Proc-Spawner's
  `large-subset-runreport.pl -q corpus-work/q -known doc/large-subset/tools/large-subset-match-known.tsv corpus-work/run`
  (commit `e5a7c17`) gave exactly the stored `runreport.txt`.
- `SHA256SUMS` holds the archive's SHA-256.

## Using it

From Proc-Spawner's directory, at commit `e5a7c17` or later: `tar -xJf .../corpus-work.tar.xz` gives `corpus-work/`;
`make corpora` fetches the pinned sources into `corpus-work/corpora/` if a step needs them.  The reports can then be
made again without running anything (`rereport.sh`, from the distribution's directory, as root, after `perl
Makefile.PL && make`, which `large-subset-builtins.pl` needs).  The runs themselves need root, the users `rc0` to
`rc3`, and `/runcompare` (Proc-Spawner's `doc/test-pools.md`, section 0).
