# The snippets Proc-Spawner's large parser rejects, run in dash and bash (2026-11-26, code label post-0.13)

`corpus-work.tar.xz` (0.7 MB; 11 MB unpacked, 12 files) holds the files of Proc-Spawner's `corpus-work/` that this
run read and wrote.  `CONTENTS.txt` lists them with sizes and the time of each part's newest file (UTC; for
`samples.*`, the time the collection [`../2026-11-22-post-0.13/`](../2026-11-22-post-0.13/) gives them).

The corpus runs of the other collections take only the snippets that the large parser accepts.  This one takes the
other 1,543 (`samples.tsv`, column `large` 0), which Proc::ShellSpawn cannot run, since it refuses them: each ran once
in dash and in `bash --posix` alone, so that it is known whether the two shells agree on it.  Its records are behind
Proc-Spawner's `README.md`, "How close to dash and bash", the part on the rejected snippets, and
`doc/large-subset/large-subset-state.md`, section 4.

## What made it

- **The snippets**: `samples.tsv` and `samples.jsonl` are those of the collection `2026-11-22-post-0.13`, byte for byte
  (the parse results of that day; Proc-Spawner's parsers have not changed since).
- **The run**: `make -o corpus-work/samples.tsv corpus-rejected` at Proc-Spawner's commit `fb9dfe2` (`main`, post-0.13),
  as root, 4 workers, started 18:27 UTC, 2 minutes 27 seconds, status 0 (`corpus-rejected.log`).  `-o` keeps make from
  making `samples.tsv` again from the corpora, which were not fetched.  The target's three steps:
  `large-subset-rejected.pl -prepare` (writes `rejected-samples.tsv`, the same with column `large` set to 1, so that the
  runner takes them, and `rejected.ids`); `large-subset-runcompare.pl -j 4 -env tmp,random,mtime -base /runcompare
  -shells dash,bash -only @corpus-work/rejected.ids` (the environment of the base run of the corpus runs; `rejected/`);
  `large-subset-rejected.pl -o doc/large-subset/tools/large-subset-rejected.tsv` (Proc-Spawner's record, which this
  collection backs).
- **Before it**, the same run with the runner of the commit before stopped at 1,196 of the 1,543 (as a try of
  2026-11-23 had): bash's `suspend -f` stops its own process group, `timeout` with it.  That run is not kept; the runner
  was fixed (Proc-Spawner's known issue X85), and this run made with the fix.  The two runs gave the same outcome for
  every snippet but `suspend -f` itself, which the first run had to have killed by hand.

## The records

`rejected/run-*.jsonl` have the form of the records of the other collections (the README of
[`../2026-11-17-post-0.12/`](../2026-11-17-post-0.12/README.md), "The records"), with the keys `dash` and `bash` only.
New since the fix: a run that the runner had to kill after 15 seconds has status 124 and `"hung"` (here only
`TL:common/suspend.md:16`, in bash).

## The counts

Compared as Proc-Spawner's match compares (messages count nowhere), dash against bash:

```
work list                         45   same 8   messages only 7   differ 30
subtle                            37   same 15   messages only 3   differ 19
subtle, open                       3   same 1   messages only 1   differ 1
foreign, both parse              938   same 72   messages only 114   differ 750   timeout 2
foreign, a shell cannot parse    520   same 1   messages only 126   differ 388   timeout 5
```

The groups are those of Proc-Spawner's README: the work list (within its lower yardstick), the subtle differences and
open verdicts (between its two yardsticks), and the foreign snippets (outside the upper one).
