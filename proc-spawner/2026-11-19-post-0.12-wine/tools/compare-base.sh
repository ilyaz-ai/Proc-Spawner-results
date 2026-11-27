#!/bin/bash
# machine-not.ids: read one by one, not a difference of the machine: NB:7781 (sed index.html | tee index.html) is a race, sed opening the file before or after tee makes it; here sed was first in the 4 Linux repeats of system1, in the base run tee
# compare-base.sh: every comparison and classification table against the project's base run (repository
# ilyaz-ai/Proc-Spawner-results, proc-spawner/2026-11-17-post-0.12: corpus-work/run, corpus-work/run-system1).
# Windows: the saved full runs (win-WAY; win-WAY-na: the 127 non-ASCII samples rerun with the text written as UTF-8),
# with base/win-WAY's records (the project's environment and workers) replacing theirs.  Chance: base/rep, 4 more runs of
# each sample of base/rep.ids per system and way.  Output in base/.
R=/work/res; O=$R/base; B=/home/user/proc-spawner/corpus-work; T=$(dirname "$(readlink -f "$0")")
cd $O || exit 1
lin() { [ $1 = posix_spawn ] && echo $B/run || echo $B/run-system1; }
win() { echo "$R/win-$1,$R/win-$1-na,$O/win-$1"; }
other() { [ $1 = posix_spawn ] && echo system1 || echo posix_spawn; }
reps() { for n in 2 3 4 5; do printf -- " -$1 rep/$2-r$n"; done; }
for w in posix_spawn system1; do
  perl $T/chance.pl -a $(lin $w) $(reps a linux-$w) -b $(win $w) $(reps b win-$w) > chance-$w.tsv
  # the machine: the base run (another container) against the Linux repeats made here; the repeats against Windows
  perl $T/chance.pl -a $(lin $w) $(reps b linux-$w) > chance-linux-base-$w.tsv
  perl $T/chance.pl $(reps a linux-$w) -b $(win $w) $(reps b win-$w) > chance-here-$w.tsv
  # machine-WAY.ids: the repeats here agree with each other (distinct 1), not with the base run, and with some Windows run
  join -t$'\t' <(awk -F'\t' 'NR > 1 && $5 == 1 && $6 == 0 {print $1}' chance-linux-base-$w.tsv | sort) \
    <(awk -F'\t' 'NR > 1 && $6 == 1 {print $1}' chance-here-$w.tsv | sort) | grep -vxF -f $T/machine-not.ids > machine-$w.ids
  perl $T/wincompare.pl -noise $(lin $(other $w)) -l cmp-$w.tsv $(lin $w) $(win $w) > cmp-$w.txt
  perl $T/classify.pl -chance chance-$w.tsv -machine machine-$w.ids $(lin $w) $(win $w) cmp-$w.tsv > cls-$w.tsv 2> cls-$w.txt
  perl $T/wincompare.pl -noise $(lin $(other $w)) -l cmp-$w-wide.tsv $(lin $w) $R/win-$w-wide > cmp-$w-wide.txt
  perl $T/classify.pl $(lin $w) $R/win-$w-wide cmp-$w-wide.tsv > cls-$w-wide.tsv 2> cls-$w-wide.txt
done
perl $T/chance.pl -a $(win posix_spawn) $(reps a win-posix_spawn) -b $(win system1) $(reps b win-system1) > chance-win-ways.tsv
perl $T/wincompare.pl -l cmp-win-ways.tsv $(win posix_spawn) $(win system1) > cmp-win-ways.txt
perl $T/classify.pl -chance chance-win-ways.tsv $(win posix_spawn) $(win system1) cmp-win-ways.tsv > cls-win-ways.tsv 2> cls-win-ways.txt
perl $T/chance.pl -a $(lin posix_spawn) $(reps a linux-posix_spawn) -b $(lin system1) $(reps b linux-system1) > chance-linux-ways.tsv
perl $T/wincompare.pl -l cmp-linux-ways.tsv $(lin posix_spawn) $(lin system1) > cmp-linux-ways.txt
# variability.tsv: per sample and kind of run (ours, system, way), the runs made on this machine in the same environment
# (Linux: the 4 repeats; Windows: the first run and the 4 repeats; the base run, made on another machine, left out)
# and the distinct results among them (status, output, messages as a multiset, calls sorted, files, after)
{ printf 'id\tshell\tenvironment\truns\tdistinct\tverdict\tsource\n'
  for w in posix_spawn system1; do
    awk -F'\t' -v w=$w 'NR > 1 { e = "-env tmp,random,mtime, base /runcompare, workers of the base run";
      printf "%s\tours/linux/%s\t%s\t%d\t%d\t%s\tproc-spawner/2026-11-19-post-0.12-wine\n", $1, w, e, $2, $3, ($3 > 1 ? "varies" : "stable");
      printf "%s\tours/wine/%s\t%s\t%d\t%d\t%s\tproc-spawner/2026-11-19-post-0.12-wine\n", $1, w, e, $4, $5, ($5 > 1 ? "varies" : "stable") }' chance-here-$w.tsv
  done; } > variability.tsv
