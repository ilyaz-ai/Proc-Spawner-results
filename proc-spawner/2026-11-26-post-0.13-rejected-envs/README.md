# The work list's candidates in example environments (2026-11-26, code label post-0.13)

`corpus-work.tar.xz` (0.7 MB; 11 MB unpacked, 36 files) holds the files of Proc-Spawner's `corpus-work/` that these
runs read and wrote.

[`../2026-11-26-post-0.13-rejected/`](../2026-11-26-post-0.13-rejected/) ran every snippet the large parser rejects once
in dash and bash alone.  One run in one environment can hide a difference, so 25 of the work list's candidates (the
snippets within the lower yardstick that no decision keeps rejected and that read something from their environment)
ran again here in example environments.  Such environments are made for the accepted snippets by a program that reads
their parse trees; a rejected snippet has none, so these were written by reading each snippet: Proc-Spawner's record
`doc/large-subset/tools/large-subset-rejected-setups.jsonl` (also here, split by environment, `rejected-setup-K.jsonl`).
The 9 other candidates read nothing from their environment (`exit -1`, `pwd --help`, `${ ls; }`, …) and had no runs
here.

## What made it

`make -o corpus-work/samples.tsv corpus-rejected-envs` at Proc-Spawner's commit `0493fee` (`main`, post-0.13), as root,
4 workers, on 2026-11-26, about a minute (`corpus-rejected-envs.log`; its first run of the comparison stopped on a fault
of the tool, fixed in that commit, and the comparison was then run alone).  `rejected/` is the base run, copied from
`2026-11-26-post-0.13-rejected/`; `rejected-sK/` is environment K (the runner's `-setup`); `samples.*` are those of
`2026-11-22-post-0.13/`, byte for byte.

## The counts

Over the base run and every environment of each of the 25 (dash against bash, messages not counted): alike in every
one 5, alike in some and not in others 8, differ in every one 12.  Proc-Spawner's record
`large-subset-rejected-envs.tsv` has each snippet with each environment's outcome.
