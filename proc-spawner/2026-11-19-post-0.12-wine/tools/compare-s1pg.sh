#!/bin/bash
# compare-s1pg.sh [DIR] (2026-11-21): as compare-s2.sh, with the records of the (s2) rerun (s2d) and then of DIR (default
# /work/res/s1pg: row (s1) with PortableGit's programs) replacing those of their snippets.
# rerun of row (s2) (without USERNAME and TMP: /work/res/s2/win-WAY) replacing those of its snippets.  The chance
# files and machine lists are those of base/ (the repeats were not made again).  Output: DIR/tables.
R=/work/res; O=$R/base; B=/home/user/proc-spawner/corpus-work; T=/work/win; D=${1:-$R/s1pg}
mkdir -p $D/tables; cp -n $O/chance-posix_spawn.tsv $O/chance-system1.tsv $O/chance-here-*.tsv $O/machine-*.ids $D/tables/; cd $D/tables || exit 1
lin() { [ $1 = posix_spawn ] && echo $B/run || echo $B/run-system1; }
other() { [ $1 = posix_spawn ] && echo system1 || echo posix_spawn; }
win() { echo "$R/win-$1,$R/win-$1-na,$O/win-$1,$R/s2d/win-$1,$D/win-$1"; }
for w in posix_spawn system1; do
  perl $T/wincompare.pl -noise $(lin $(other $w)) -l cmp-$w.tsv $(lin $w) $(win $w) > cmp-$w.txt
  perl $T/classify.pl -chance chance-$w.tsv -machine machine-$w.ids $(lin $w) $(win $w) cmp-$w.tsv > cls-$w.tsv 2> cls-$w.txt
done
