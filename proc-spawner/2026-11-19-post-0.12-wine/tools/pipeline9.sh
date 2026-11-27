#!/bin/bash
# pipeline9.sh (2026-11-19): pipeline8.sh, but Windows runs again only the samples the project's environment or worker
# can change (base/rerun.ids: those not the same in the saved runs against the base run, in either way, and those whose
# text reaches /tmp, /var/tmp, /dev/shm, /dev/*random, $RANDOM, mktemp, shuf, sort -R, TMPDIR); the rest of each
# Windows run is the saved one (win-WAY, win-WAY-na).  From pipeline8.sh: ours under Wine against the project's own Linux runs of 2026-11-17/18 (repository
# ilyaz-ai/Proc-Spawner-results, proc-spawner/2026-11-17-post-0.12: corpus-work/run, the base run; corpus-work/run-system1,
# through Run), whose code of ours and of the recorders is that of the Windows build (6c084cc; checked with git diff).
# Windows: the project's environment (-env tmp,random,mtime), each sample on the worker it had there (-workers-from).
# Then 4 repeats, per system and way, of the samples not the same in some comparison: Linux as the base run was made
# (dash, bash --posix and ours; same environment and workers), Windows as above.  One run at a time; .done skips a step.
cd /work/ps; T=doc/large-subset/tools; S="corpus-work/samples.jsonl corpus-work/samples.tsv"; R=/work/res; O=$R/base
B=/home/user/proc-spawner/corpus-work; RUNLIB=/work/run/blib/lib
mkdir -p $O/rep
clean() { for u in rc0 rc1 rc2 rc3; do find /tmp /var/tmp /dev/shm -xdev -mindepth 1 -maxdepth 1 -user $u -exec rm -rf {} + 2>/dev/null; done; true; }
note() { echo "$(date -u +%FT%TZ) $*" >> $R/pipeline.log; }
step() { local out=$1; shift; [ -e $out/.done ] && return 0; clean; "$@" >> $out.log 2>&1
  local n=$(cat $out/run-*.jsonl 2>/dev/null | perl -ne 'BEGIN { if (length $ENV{LIST}) { open my $l, "<", $ENV{LIST} or die; %w = map { chomp; ($_ => 1) } <$l> } } /"id":"((?:[^"\\]|\\.)*)"/ or next; $s{$1}++ if !%w || $w{$1}; END { print scalar keys %s }')
  note "base ${out#$O/}: $n samples"; [ "$n" -ge "$EXPECT" ] && touch $out/.done; }
linux() { unshare -n perl $T/large-subset-runcompare.pl -j 4 -env tmp,random,mtime -base /runcompare "$@"; }
win() { unshare -n perl /work/win/runwine.pl -j 4 -env tmp,random,mtime -user rc -base /runcompare -dist /work/psw -tools $T "$@"; }
note "pipeline9 start"
EXPECT=$(perl -e 'open my $t, "<", shift; my $h = <$t>; chomp $h; my @h = split /\t/, $h; my %c; @c{@h} = 0..$#h; my %a; while (<$t>) { chomp; my @f = split /\t/, $_, -1; $a{$f[$c{id}]} = 1 if $f[$c{large}] } open my $r, "<", shift; my $n = 0; while (<$r>) { chomp; $n++ if $a{$_} } print $n' corpus-work/samples.tsv $O/rerun.ids)
LIST=$O/rerun.ids step $O/win-posix_spawn win -workers-from $B/run -only @$O/rerun.ids $S $O/win-posix_spawn
LIST=$O/rerun.ids step $O/win-system1 win -run -runpm /work/run/Run.pm -workers-from $B/run-system1 -only @$O/rerun.ids $S $O/win-system1
for d in win-posix_spawn win-system1; do [ -e $O/$d/.done ] || { note "base $d incomplete: stop"; exit 1; }; done
if [ ! -s $O/rep.ids ]; then
  perl /work/win/wincompare.pl -l $O/pre-posix_spawn.tsv $B/run $R/win-posix_spawn,$R/win-posix_spawn-na,$O/win-posix_spawn > /dev/null
  perl /work/win/wincompare.pl -l $O/pre-system1.tsv $B/run-system1 $R/win-system1,$R/win-system1-na,$O/win-system1 > /dev/null
  perl /work/win/wincompare.pl -l $O/pre-win-ways.tsv $R/win-posix_spawn,$R/win-posix_spawn-na,$O/win-posix_spawn $R/win-system1,$R/win-system1-na,$O/win-system1 > /dev/null
  perl /work/win/wincompare.pl -l $O/pre-linux-ways.tsv $B/run $B/run-system1 > /dev/null
  cat $O/pre-*.tsv | awk -F'\t' '!/^#/ && $2 !~ /^same/ {print $1}' | sort -u > $O/rep.ids
  note "base rep.ids: $(wc -l < $O/rep.ids) samples"; fi
EXPECT=$(wc -l < $O/rep.ids)
for n in 2 3 4 5; do
  step $O/rep/linux-posix_spawn-r$n linux -workers-from $B/run -only @$O/rep.ids $S $O/rep/linux-posix_spawn-r$n
  step $O/rep/linux-system1-r$n linux -run $RUNLIB -workers-from $B/run-system1 -only @$O/rep.ids $S $O/rep/linux-system1-r$n
  step $O/rep/win-posix_spawn-r$n win -workers-from $B/run -only @$O/rep.ids $S $O/rep/win-posix_spawn-r$n
  step $O/rep/win-system1-r$n win -run -runpm /work/run/Run.pm -workers-from $B/run-system1 -only @$O/rep.ids $S $O/rep/win-system1-r$n
done
note "base END"
