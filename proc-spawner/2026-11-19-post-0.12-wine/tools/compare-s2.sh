#!/bin/bash
# compare-s2.sh [DIR] (2026-11-21; DIR: the rerun's directory, default /work/res/s2): compare-base.sh's comparison and classification of each way, with the records of the
# rerun of row (s2) (without USERNAME and TMP: /work/res/s2/win-WAY) replacing those of its snippets.  The chance
# files and machine lists are those of base/ (the repeats were not made again).  Output: DIR/tables.
R=/work/res; O=$R/base; B=/home/user/proc-spawner/corpus-work; T=/work/win; D=${1:-$R/s2}
mkdir -p $D/tables; cp -n $O/chance-posix_spawn.tsv $O/chance-system1.tsv $O/chance-here-*.tsv $O/machine-*.ids $D/tables/; cd $D/tables || exit 1
lin() { [ $1 = posix_spawn ] && echo $B/run || echo $B/run-system1; }
other() { [ $1 = posix_spawn ] && echo system1 || echo posix_spawn; }
win() { echo "$R/win-$1,$R/win-$1-na,$O/win-$1,$D/win-$1"; }
for w in posix_spawn system1; do
  perl $T/wincompare.pl -noise $(lin $(other $w)) -l cmp-$w.tsv $(lin $w) $(win $w) > cmp-$w.txt
  perl $T/classify.pl -chance chance-$w.tsv -machine machine-$w.ids $(lin $w) $(win $w) cmp-$w.tsv > cls-$w.tsv 2> cls-$w.txt
done
