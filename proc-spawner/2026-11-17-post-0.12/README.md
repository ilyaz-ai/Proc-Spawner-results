# Proc-Spawner's corpus runs of 2026-11-17 (code label post-0.12)

`corpus-work.tar.xz` (8.1 MB; 367 MB unpacked) is the directory `corpus-work/` of the session that
made the runs, as it stood on 2026-11-19, without `corpora/` (the pinned sources, which
`make corpora` in Proc-Spawner fetches again).  `CONTENTS.txt` lists its parts with sizes and
the time of each part's newest file (UTC).

These are the records behind the corpus counts of Proc-Spawner's documents: its `README.md`, "How
close to dash and bash"; `doc/large-subset/large-subset-state.md`, section 7;
`doc/large-subset/large-subset-environment.md`, sections 9 to 12.  This file says what the records
hold and how those documents read them; the documents themselves say what the counts mean for the
module.

## What made it

- `make corpus-all` of 2026-11-17 on Proc-Spawner's `main`.  The records of that run are in
  Proc-Spawner's `Changes`, under post-0.12: the run with IN1 (code of commit `c5ec6a5`; commit `817a221` records it) and the stopgap of
  A24 (b), which ran again the 4,060 samples that mention a program that never reads its standard
  input, or `zcat` (commit `fd17f98` is the code; commit `577b924` records the run).  The run
  ended 13:51 UTC (`all.log`: `END 0`).  The earlier run of that morning with IN1 alone is not
  kept.  (In `all.log`, the base run's step of that stopgap shows "3291 samples to run, 37119 done
  before": the records do not say which snippet is of which commit.)
- `env/` and `envx66.log`: the environment variants run again after X66's fix (14:29); the variants'
  own runs, not `env/base`, which had nothing to run again.
- Of 2026-11-18: `run-system1/` (every sample through Run, `system1`), `run-system1-again/`,
  `run-posix-now/`, `run-posix-now2/` (the 60 samples whose result changed through Run, run again),
  `rep-posix-1/` to `-6/` and `rep-system1-1/` to `-6/` (6 repeats each of one of them, `NB:4909`,
  `one.ids`), and the reports `runreport*.txt`.  In `run/` and `q/`, `env.txt`, `programs.txt`
  and `.done` were written again on 2026-11-18 09:00; the per-sample records `run-*.jsonl` are
  those of 2026-11-17 (12:01-12:04).
- Checked 2026-11-19: Proc-Spawner's `large-subset-matchreport.pl -raw` on these runs gives
  exactly the stored `match-raw.txt`.  Checked 2026-11-22, with Proc-Spawner's `main` (commit
  `97b63f2`): `large-subset-runreport.pl -q corpus-work/q -known
  doc/large-subset/tools/large-subset-match-known.tsv corpus-work/run` gives the stored
  `runreport.txt` (two lines of equal count in the other order).

(Labels such as IN1, A24, X66, X27 are Proc-Spawner's: its known issues, `doc/pspawn-known-issues.md`,
and the decisions named in its documents.)

## What was run

- **The snippets**: 40,410 pieces of shell text taken from six public collections, the ones that
  Proc-Spawner's large parser accepts: the rows of `samples.tsv` whose column `large` is 1.
  `samples.tsv` has a row for each of the 41,952 snippets taken (40,410 with `large` 1, 1,542 with 0);
  `samples.jsonl` holds every piece extracted (45,501 lines, 45,479 distinct ids), also those dropped
  before parsing (`drops.tsv` says why), among them all 578 lines (556 ids) of a seventh source, `MK:`.  A snippet's id says
  its source: `TL:` tldr (29,232), `NB:` NL2Bash (10,039), `SC:` ShellCheck's tests (1,021), `PB:` the
  pure bash bible (49), `PS:` the pure sh bible (43), `BC:` the bash Cookbook (26).
- **The three shells**: dash (`/usr/bin/dash -c TEXT`), bash as `/usr/bin/bash --posix -c TEXT`, and
  Proc::ShellSpawn (*ShellSpawn* below), the module of Proc-Spawner that runs shell text without a
  shell (through Proc-Spawner's test driver `t/try.pl`).  Dash 0.5.12, bash 5.2.21, Perl 5.38.2, Ubuntu
  24.04.  The records name ShellSpawn's result `ours`, a key; the reports of this collection, made with
  the tools of before post-0.13, also call ShellSpawn "ours" in their text (the class `OURS`, "ours =
  dash = bash", "Ours against ours"), where the tools of post-0.13 say ShellSpawn.  Since 2026-11-23 (Proc-Spawner's
  decision D5) its tools also name ShellSpawn `shellspawn` in what they write (the key `shellspawn`, the class
  `SHELLSPAWN`, the options `-shells shellspawn`, `-shellspawn-from`, `-shellspawn-vs`, `-shellspawn`); they still read
  the key `ours` of these records and accept the old option names.
- **Each run isolated** (Proc-Spawner's `doc/large-subset/tools/large-subset-runcompare.pl`, as root
  under `unshare -n`, 4 workers): worker K runs as the user `rcK` in the directory `/runcompare/wK/run`
  (so `run-K.jsonl` holds worker K's snippets), each run in a fresh copy of the same small directory
  of files, with `HOME` inside it; limits on CPU time, processes and the size of each file written
  (20 MB); a timeout of 5 seconds; background jobs still running when the shell ends get up to 5
  seconds more, then every process of the user is killed.  `run/env.txt` names the environment of
  these runs, `-env tmp,random,mtime`: a fresh `/tmp`, `/var/tmp` and `/dev/shm`; one fixed file of
  1 MiB in place of `/dev/urandom` and `/dev/random`; one fixed time (2020-01-01 00:00 UTC) on every
  file of the copied directory.
- **The programs a snippet calls** are recorders, on `PATH`: one for each name of Proc-Spawner's
  `doc/large-subset/tools/large-subset-programs.txt` (its SHA-256 in `run/programs.txt`), whether the
  machine has the program or not.  A recorder logs the call (the part `rec` below).  For 41
  names it then runs the real program (`cat`, `grep`, `egrep`, `fgrep`, `sed`, `awk`, `sort`, `head`,
  `tail`, `wc`, `tr`, `cut`, `uniq`, `seq`, `expr`, `basename`, `dirname`, `printenv`, `env`, `xargs`,
  `tee`, `ls`, `mkdir`, `touch`, `cmp`, `diff`, `od`, `rev`, `nl`, `paste`, `join`, `fold`, `comm`,
  `tac`, `realpath`, `readlink`, `stat`, `sha256sum`, `md5sum`, `base64`, `yes`); every other recorder
  prints nothing and exits 0, after reading what the snippet feeds it.  So `rm`, `mv`, `cp`, `find`,
  `git`, `sudo` ... are only logged, and a name not on the list is "not found" in all three shells:
  dash's status is 127 in 22,949 of the 40,410.
- `echo`, `printf`, `test`, `[`, `true`, `false`, `pwd` and `kill` are not recorders: dash and bash run
  their builtins, ShellSpawn runs Perl code that does what the coreutils programs do, and for `kill` the
  program `kill`.  These calls are not logged in `rec`.

## The records

`run/run-K.jsonl`: one JSON object per line, one line per snippet.  Most other directories of runs
(`run-system1/`, `step2/sN/`, `env/*/`, ...) hold files of the same form, some with `ours` alone.

| Field | What it holds |
|---|---|
| `id`, `src`, `text` | the snippet's id, its source, its text |
| `features` | the differences between dash and bash that the snippet's text uses, as Proc-Spawner's detector (`large-subset-features.pl`) and ShellCheck's portability codes find them, comma-separated `name:VERDICT:SOURCE:detail`, SOURCE being `P` (the detector's own feature), `SC` (a ShellCheck code), `E` (rule E) or `user` (a ruling, as `interactive:X:user:B2`); empty for most |
| `verdict` | a summary of `features`: `B` a blatant difference, `S` a subtle one, `X` one where the subset runs a program in place of both shells' builtin, `O` one whose verdict is still open (a verdict kept by hand in Proc-Spawner's `large-subset-verdicts.txt` that is none of the others; 3 snippets), `-` none (Proc-Spawner's `large-subset-state.md`, section 1, R-blatant) |
| `dash`, `bash`, `ours` | the result of each shell, as below |

Each result:

| Part | What it holds |
|---|---|
| `status` | the exit status, an integer; `"signal N"` when the shell itself was killed by signal N.  124: the 5-second timeout (`timeout`'s status; 137 if it had to kill); 153 or `"signal 25"`: the file-size limit (SIGXFSZ); 127: not found; 248, ShellSpawn only: a form it does not support at run time |
| `out`, `err` | standard output and standard error as written, each cut to 4,000 characters (then `\n[...cut]` follows; `rec` and `builtins` are cut so too).  The messages in `err` start with the shell's prefix: dash `/usr/bin/dash: LINE: `, bash `/usr/bin/bash: line LINE: `, ShellSpawn `sh: ` (no line number) |
| `files` | what the run's directory holds afterwards, one line each, in the order of a walk of the directory with each directory's entries sorted (so `dir/`, `dir/sub/`, `dir/sub/y.sh`, `dir/x.txt`, then `dir.md5`): `PATH SIZE HASH` for a file (HASH: the first 12 hex digits of the SHA-256 of its contents; `e3b0c44298fc` is an empty file), `PATH/` for a directory, `PATH -> TARGET` for a symbolic link; `?` where the size or the hash could not be read.  The copied directory's own files are there too |
| `files_nomsg` | the same without sizes, `PATH HASH`, the hash taken of the contents without the lines that start as a shell's message (`dash: N: `, `bash: line N: ` or `bash: `, each after an optional path; `sh: `) |
| `rec` | the programs called, one line per call: the name and the arguments, separated by the character `\x1f`; where the program read input from the snippet, `\x1e` and `BYTES SHA256` of what it read (`65536+ ...` when the recorder stopped at 64 KB; `closed`, `unreadable`).  The lines come in the order of the calls, which varies between pipeline elements |
| `after` | `killed` where background jobs were still running 5 seconds after the shell ended (absent otherwise) |

Encoding: `text` is UTF-8.  `out`, `err`, `rec` (and `builtins`) hold the bytes as written, each byte one character
(Latin-1): a program's UTF-8 `“` reads `â\x80\x9c`; encoding these strings as Latin-1 gives the bytes back.  So the cut
at 4,000 characters is a cut at 4,000 bytes.

In `q/` (and the other runs with `-q`: `match/q*`, `step3*/q*`), ShellSpawn alone ran with more logging: each
line of `rec` starts with its caller and `\x1d`, and `builtins` logs every command ShellSpawn ran itself, one line
each: `HANDLER\x1dSETTINGS\x1dNAME\x1fARG...`, where HANDLER is ShellSpawn's function (`not found`, `x_set`,
`Proc::ShellSpawn::inproc`, `...::b_test`, ...) and SETTINGS the assignments or, for `inproc`, the
environment (entries separated by `\x1e`).

## How the reports compare the shells

**`runreport.txt`** (and `runreport-x.txt`, `runreport-system1.txt`): Proc-Spawner's
`large-subset-runreport.pl`, the base run alone.  `runreport-x.txt` (`-x`) adds the calls of external
programs, compared as sorted lists, and where dash and bash agree and ShellSpawn differs, call by call.
`runreport-system1.txt` is `-ours-from corpus-work/run-system1 -known ... corpus-work/run`: ShellSpawn
through Run with dash and bash of `run/` (checked: its table comes out the same), then ShellSpawn against
ShellSpawn of `run/`.  Snippet by snippet:

1. If any of the three ran out of time (status 124 or 137), the snippet is `timeout`, not compared.
2. Otherwise each result is reduced to `status`, `out`, `rec` with its lines sorted, and `files` (with
   sizes; not `files_nomsg`), and compared;
3. `err` is compared apart: each shell's prefix taken off, the newlines dropped, the characters sorted.
   So other wording is seen; the same messages in another order are not.  The prefixes, as the tool's
   patterns take them: dash's `(\S*/)?dash: N: ` and bash's `(\S*/)?bash: (line N: )?` wherever they stand
   in a line (the shells write a pipeline element's message in pieces), ShellSpawn's `sh: ` at the start of a
   line only.  Where a message ends without a newline and the next prefix follows at once, `\S*/` also
   takes the word glued before the path: `piactl: not found/usr/bin/dash: 1: ` loses `found` too.  So
   6 snippets of tldr (`TL:common/piactl.md:20`, `tsc.md:16`, `gst-play-1.0.md:8`, `mh_metric.md:24`,
   `kubectl-run.md:17`, `zeroclaw-channel.md:20`) come out `msg-own`, though ShellSpawn words its messages
   as dash does there.  This was a fault of the pattern (Proc-Spawner's known issue X82), fixed after
   these reports were made: the path must now begin with `/`.  With the fixed tool the base run has
   `msg=dash` 23,293 and `msg-own` 66 (the stored `runreport.txt`: 23,287 and 72); the variant `sigpipe`
   of `env/` has 34 class changes (+10 noisy), not 38 (+15); no count of the match changes.

The classes (the columns), each snippet in exactly one:

| Class | Meaning |
|---|---|
| `same` | all three agree, messages too |
| `msg=dash`, `msg=bash`, `msg-own` | all three agree but in the messages; ShellSpawn's are worded as dash's, as bash's, or as neither |
| `OURS` | dash and bash agree, ShellSpawn differs (beyond the messages); `SHELLSPAWN` in Proc-Spawner's reports made since 2026-11-23 |
| `chance` | as `OURS`, but Proc-Spawner's `large-subset-match-known.tsv` names the snippet chance for the base run: other runs showed dash and bash themselves varying there (here `NB:685`, `NB:5152`, `NB:6795`) |
| `=dash`, `=bash`, `neither` | dash and bash differ (beyond the messages); ShellSpawn agrees with dash, with bash, or with neither |
| `timeout` | a shell ran out of time |

"coreutils involved" (the second table) holds the snippets where ShellSpawn did the work of `echo`,
`printf`, `test`, `[`, `pwd` or `kill` (its log in `q/` shows such a call from ShellSpawn, or the name stands
where a command does in the text), "no coreutils" the others.  The tables "by the parts that differ"
name the parts (status, out, rec, files) that differ, ShellSpawn against both shells, or dash against bash.
In Proc-Spawner's `README.md`, "One run of every accepted snippet": "Same" = `same`; "Only the
messages differ" = `msg=dash` + `msg=bash` + `msg-own` (23,287 + 34 + 72 = 23,393); "dash and bash
agree, ShellSpawn differs" = `OURS` (4); "the same, known chance" = `chance` (3); "dash and bash
differ" = `=dash` + `=bash` + `neither` (965 + 103 + 152 = 1,220); "Did not end" = `timeout` (14); its
rows "the six commands" and "no such command" are "coreutils involved" and "no coreutils".

**`match.txt`**: the headline of Proc-Spawner's `README.md` ("We do what both shells do, in every
run, in 38,593 snippets", and so on): Proc-Spawner's `large-subset-matchreport.pl` (`make
corpus-match`, the recipe in its `doc/corpus.mk`).  Each snippet is counted over every environment
it ran in: the base run (`run/`; for the snippets of step 2 their records in `step2/base/` replace those
of `run/`), step 2's example setups
(`step2/sN/`), and step 3's (`step3/base/`, `step3/sN/`, `step3-affects-shell/base/`,
`step3-affects-shell/sN/`; step 3's runs, its `base/` too, each in a copy-on-write root, `-env
cowroot`).  The second base runs (`step2/base2/`, `step3*/base2/`) only test whether a snippet's class
is stable; the environment variants of `env/` are not among them either.  4,728 snippets
ran in some environment beyond the base run; for the other 35,682, "every environment" is the base
run.  The `-q` runs (`qbase/`, `qsN/`) are not environments: they hold ShellSpawn alone, for its calls.  In
each environment the classes are those above (`rec` with its lines sorted), but messages count nowhere: `err` is not
compared, the lines of `out` that start as a shell's message (the pattern of `files_nomsg`) are left out, and files are compared by
`files_nomsg`.  An environment where a shell ran out of time is not compared; a snippet is `timeout`
only if it ran out of time in every environment.  So `match.txt` has 13 timeouts where the base run
has 14: `NB:4449` (`grep -Ril ... /`) ended in step 3's runs, alike in all three.

- *Tree 1* sorts the snippets by agreement: ShellSpawn = dash = bash in every environment (38,593); timeout
  (13); dash = bash and ShellSpawn differs (7); dash and bash differ (1,797), and then ShellSpawn as dash, as bash,
  as neither, or "depends on the environment" (ShellSpawn = dash in some environments and = bash in others;
  = dash in some and neither in others; = bash and neither; all three).  A snippet whose shells agree in every environment is in the first or
  the third box; one whose shells differ in some environment is sorted only by the environments where
  they differ: there an environment where dash = bash and ShellSpawn differs does not count for its box
  (it does for the reasons of Tree 2).  So the 7 of the box "dash = bash; ShellSpawn differs" are not the base
  run's 4 `OURS` and 3 `chance`: `NB:685` (chance there) is in "depends on the environment", and
  `NB:9614` (the same in the base run) is in the 7, by step 3's setups, where ShellSpawn stops with 248.  The columns on the right split each box: `≠coreutil`, the snippet
  runs one of the six commands with arguments for which the coreutils program differs from that
  shell's builtin, in every environment where ShellSpawn differs from a shell (and ShellSpawn = coreutils);
  `¬coreutil`, it runs none of the six; `rest`, the others.
- *Tree 2* adds the reason Proc-Spawner gives each difference, and the line under it sums them: of
  the 1,804 = 7 + 1,797, 1,629 legalized by rulings, 88 awaiting the decision A12, 45 chance, 42 not
  legalized.  These reasons come from Proc-Spawner's `doc/large-subset/tools/large-subset-match.tsv`,
  which the same command writes, and from the decisions in its documents: they cannot be recomputed
  from this collection.  The rulings (Proc-Spawner's `large-subset-environment.md`, section 11, "The
  rulings"): A5, where dash and bash differ at run time, ShellSpawn may side with dash; G16, `~` with
  `HOME` unset is the home from the password file, as bash; builtin-vs-coreutils, the six commands
  done as the programs; B2, the interactive builtins (`history`, `fc`, `bind`, `help`) do nothing;
  `$0`, each shell is started under its own name; rule E, the better behaviour where the shells
  differ; A4, `set` and `export` without operands are outside the subset at run time; Q2, `printf -v`
  stays with the program; "the runner", a difference of the test setup.  A12 (awaiting): `~` with
  `HOME` empty.  Chance: results that change from run to run.
- The level table at the top: the levels below, and whether dash and bash agree beyond the messages.

**`match-raw.txt`**: the same match with the comparison used before 2026-11-11 (`-raw`): `out` as
written and `files` with sizes, so a message that went to standard output or into a file counts.
Proc-Spawner's `large-subset-match-raw.md` reads it.

## The levels

`levels.tsv` (id, level, reasons, text; `levels.txt` sums it) sorts each snippet by how far its result
can change with the environment, from its text (Proc-Spawner's `large-subset-environment.md`, section
1): *strict* (392 = 365 + 27), it cannot come out otherwise anywhere; *held* (2), not under assumptions
that held everywhere tested; *almost strict* (34,302), not while named assumptions hold (an external
program does the same with the same arguments, input and environment; a pipeline's writer dies
silently when its reader stops; ...); *values passed on unchanged* (671 = 664 + 7) and *split*
(1,483 = 1,476 + 7), the shell at most passes a value from the environment on to a command (split at
`$IFS` and matched against file names, for *split*); `undecided` (3,560), the rest.  `match.txt`
splits that last level into *partially decided* (3,508: what they depend on is named, and step 2's or
3's setups vary it: the snippets of that level that have setups) and *undecided (the rest)* (52 = 0 +
52: no setup could be made).  N + M: N sorted by Proc-Spawner's programs, M by Claude (an AI) reading
them; `levels.tsv` does not mark which, Proc-Spawner's `large-subset-ai-classes.tsv` lists the M.
The column `text` may hold a tab: split a line at its first three tabs only; and one holds a carriage return (`SC:Analytics.hs:prop_checkUuoeVar3`): split the file at newlines only.  392 + 2 + 34,302 + 671 + 1,483 + 3,560 = 40,410.

## How a snippet is to be run, and what the records say of chance

Whether ShellSpawn's result on a snippet can be compared with the shells' after one run, or only over
example environments, or not at all (chance, never ending), is decided from:

- its level and codes: `levels.tsv` (the codes with their `passthrough(…)`, as in Proc-Spawner's
  `large-subset-provenance.tsv`);
- for the snippets with example environments: what each depends on, the setups, and every shell's
  results in each (`step2/deps.jsonl`, `step2/setup-samples.tsv`, `step2/sN/`; the same in `step3/` and
  `step3-affects-shell/`);
- the worker each snippet ran in (`run/run-K.jsonl`; runs to be joined with these take it with
  `-workers-from`) and the environment (`run/env.txt`);
- and records that are not here but in Proc-Spawner's distribution on CPAN, `doc/large-subset/` (the repository's
  [`README.md`](../../README.md), "What is not here", lists them with the rest of what this repository lacks): step 3's class of each snippet
  (`tools/large-subset-step3.tsv`: pass, split, control, affects-shell; here only which of `step3/` and
  `step3-affects-shell/` holds a snippet shows its class), the 93 snippets classified by Claude reading
  them (`tools/large-subset-ai-classes.tsv`), the snippets known to be chance and the rulings
  (`tools/large-subset-match-known.tsv`, `tools/large-subset-match.tsv`).

A later run of ShellSpawn alone can be joined with the shells' results here only where the snippet does
not read what the machine has: run in another container, 20 snippets that read `/etc/passwd`,
`/etc/group`, `/lib` or `/proc/config.gz`, or print dates, came out as "ShellSpawn differs" with
unchanged code (`../2026-11-21-post-0.13-ours-alone-provisional/README.md`).

What varies from run to run (counted 2026-11-22 from the records, by status, output, calls sorted and
files without messages):

- Two runs of all three shells in one environment exist for 10,464 of the 40,410 snippets: `step2/base`
  and `base2` (2,902 snippets), `step3/base` and `base2` (2,475), the same in `step3-affects-shell/`
  (1,033), `env/base` and `base2` (7,003), `env/sbase` and `sbase2` (1,248); a snippet may be in several.
  Most records of a `base2` were made on an earlier day (a run skips what its directory has; `all.log`:
  "411 samples to run, 2491 done before").  Between the two runs dash differs in 119 snippets, bash in
  126, ShellSpawn in 110 (none in step 2 and in step 3's control; 6, 10 and 2 in affects-shell; the rest in
  `env/`).
- 15 runs of each shell (3 modes of ShellSpawn's end, 5 runs each) for the 44 snippets with a background
  job: `endmodes/`.
- The other snippets have one run of dash and one of bash.  The repeats of 2026-11-18 (`rep-*`,
  `run-posix-now*`, `run-system1-again/`) and those of the Wine collection (4 per way of 588 snippets, its
  `tables/variability.tsv`) are of ShellSpawn alone.  The races of step 3 were not run again this time
  (`races/repeat.txt`).
- Which snippets the project counts as chance (45 in `match.txt`) comes from their codes (process IDs,
  times, random numbers, races), from these runs, and from runs by hand of a few snippets (50 or 200 runs
  each, told in Proc-Spawner's documents), whose records are not kept; the list is Proc-Spawner's
  `large-subset-match-known.tsv`.  A record of what varies, made from every run (Proc-Spawner's `TODO`,
  part B, "Chance from every run"), does not exist yet.

## The other parts

- `run/`: the base run.  `q/`: ShellSpawn alone over the same snippets with the logging of `-q` (above),
  for "coreutils involved" and `threeway.txt`.
- `run-system1/`: ShellSpawn alone through Run (`PROC_SPAWNER_MISSING="posix_spawn fork"`: the module's
  `system1`, Perl's own `system`), 2026-11-18; `runreport-system1.txt` compares it with dash and bash
  of `run/`, and ends with ShellSpawn through Run against ShellSpawn of `run/`: 60 differ, `system1-changed.ids`.
  `run-posix-now/` and `run-posix-now2/`: those 60 run again twice the usual way, `run-system1-again/`
  once more through Run; `pp.txt`: `run-posix-now2/` against `run-posix-now/` (44 differ),
  `sp.txt`: `run-system1-again/` against `run-posix-now/` (45; the one more is `NB:4909`, repeated in
  `rep-*`).
- `step2/`: X27's step 2 (Proc-Spawner's `large-subset-environment.md`, section 10): `deps.jsonl`
  (what each snippet depends on), `setup-K.jsonl` (the example setups), `sK/` (the runs, all three
  shells, with setup K), `base/`, `base2/` (runs without setups, for noise).  `step3/`,
  `step3-affects-shell/`: step 3 (section 12), the classes control and affects-shell, with their own
  `match.txt`; `qbase/`, `qsK/`: their `-q` runs.
- `env/`: the environment variants (section 9): `v-NAME/` a variant's runs (`env.txt` says what it
  changes), `base/`, `sbase/` and `base2/`, `sbase2/` the runs it is compared with and their second
  runs (noise), `cmp-NAME.txt` the comparisons, `ids-*.txt` the snippets each ran.
- `match/`: `match0.tsv`, the per-snippet table of a first pass (before its `-q` runs; the reasons of
  Tree 2 are not final there), `q.ids` its snippets, `qbase/`, `qsK/` their `-q` runs,
  `threeway.txt` their calls of the six commands.
- `threeway.txt`: each distinct call of the six commands that ShellSpawn made in the base run, run alone by
  dash's builtin, bash's builtin and the program (Proc-Spawner's `README.md`, "The six commands, one
  call at a time"); `builtins.txt`, `builtins.jsonl`: every call of a builtin (`cd`, `read`, `set`, `export`, ...), a setting alone or a
  command not found that ShellSpawn made, run alone in dash, bash and ShellSpawn.
- `levels.tsv`, `levels.txt`, `blocks.jsonl` (the snippets cut into blocks for the levels); `parse.txt`
  (the parse results per source), `drops.tsv` (the extracted pieces left out, and why),
  `large-scan.jsonl` (the scan), `samples.jsonl`, `samples.tsv`.
- `endmodes/`: ShellSpawn's wait at exit for its background jobs, each mode of `PROC_SHELLSPAWN_END` 5 times
  (`repeat.txt`); `races/`: the races run again (none this time).
- `all.log`: the log of `make corpus-all` (each command and how it ended); `heartbeat.sh`,
  `heartbeat.txt`, `watch.sh`: the session's watch over the run.

## How to use it

```bash
cd Proc-Spawner && mkdir -p corpus-work && tar -xJf /path/to/corpus-work.tar.xz -C corpus-work
```

then `make corpora` for `corpora/` if a step needs the sources.  The tools that read these
records are in Proc-Spawner's `doc/large-subset/tools/`; `doc/test-pools.md`, section 0, says
which `make` target makes and reads which part.  What only Proc-Spawner has: those tools; the list
of chance (`large-subset-match-known.tsv`) and the reasons per snippet (`large-subset-match.tsv`); the
list of programs (`large-subset-programs.txt`); the text of the rulings and of the levels.
