#!/bin/bash
# linux-varies.sh IDS OUT.tsv (2026-11-21): the snippets of IDS whose result of Proc::ShellSpawn on Linux differs between
# runs of the same setup, in any record kept: from the base run's collection (2026-11-17-post-0.12/corpus-work, here
# CW): env/base and env/base2 (g2, 7,003 snippets); run-posix-now, run-posix-now2, rep-posix-1..6 (g1, 60 snippets,
# 2026-11-18; not run/, made a day earlier: it differs from them in 57 of 58); run-system1, run-system1-again,
# rep-system1-1..6 (h1); and the 4 Linux repeats per way made where Windows ran (g3, h3).  Not q/: it logs the builtins,
# and differs from run/ in 16,390 results.  OUT: id, group (one line per group in which it differs).
IDS=$1; OUT=$2; CW=${CW:-/home/user/proc-spawner/corpus-work}; R=${REP:-/work/res/base/rep}; L="perl $(dirname $0)/lv.pl $IDS"
cd $CW || exit 1; t=$(mktemp -d)
$L now=run-posix-now now2=run-posix-now2 $(for i in 1 2 3 4 5 6; do printf "rep$i=rep-posix-$i "; done) > $t/g1.tsv
$L base=env/base base2=env/base2 > $t/g2.tsv
$L $(for i in 2 3 4 5; do printf "r$i=$R/linux-posix_spawn-r$i "; done) > $t/g3.tsv
$L run1=run-system1 again=run-system1-again $(for i in 1 2 3 4 5 6; do printf "rep$i=rep-system1-$i "; done) > $t/h1.tsv
$L $(for i in 2 3 4 5; do printf "r$i=$R/linux-system1-r$i "; done) > $t/h3.tsv
for g in g1 g2 g3 h1 h3; do awk -F'\t' -v g=$g 'NR > 1 && $3 > 1 {print $1 "\t" g}' $t/$g.tsv; done | sort > $OUT; rm -r $t
