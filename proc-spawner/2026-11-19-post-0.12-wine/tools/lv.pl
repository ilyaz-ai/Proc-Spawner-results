#!/usr/bin/perl
# (2026-11-21, for linux-varies.sh)
# lv.pl IDS NAME=DIR ...: for each id of IDS (or all ids of the first DIR when IDS is "-"), the results of ours in each
# run (key as chance.pl's), printed as: id, runs, distinct, and per run the letter of its result (A, B, ...)
use strict; use warnings; use JSON::PP;
my $ids = shift; my @runs = map { [split /=/, $_, 2] } @ARGV;
sub msgs { my $t = shift // ''; $t =~ s/^(?:(?:\S*\/)?(?:dash|bash|sh): (?:\d+: |line \d+: )?)//mg; join '', sort split //, $t }
sub key { my $o = shift; return "error:" . $o->{error} if $o->{error};
  join "\0\0", map { my $k = $_; my $t = $o->{$k} // ''; $t = join "\n", sort split /\n/, $t if $k eq 'rec'; $t = msgs($t) if $k eq 'err'; $t } qw(status out err rec files after) }
my %want; if ($ids ne '-') { open my $i, '<', $ids or die; %want = map { chomp; ($_ => 1) } <$i> }
my %k;   # id -> run name -> key
for my $r (@runs) { my ($n, $d) = @$r; for my $f (glob "$d/run-*.jsonl") { open my $i, '<', $f or die;
  while (<$i>) { /"id":"((?:[^"\\]|\\.)*)"/ or next; next if %want && !$want{$1}; my $x = eval { decode_json($_) } or next; $k{$x->{id}}{$n} = key($x->{ours}) } } }
print join("\t", 'id', 'runs', 'distinct', map $_->[0], @runs), "\n";
for my $id (sort keys %k) { my %l; my $c = 'A'; my @cols = map { my $v = $k{$id}{$_->[0]}; defined $v ? ($l{$v} //= $c++) : '-' } @runs;
  print join("\t", $id, scalar(grep $_ ne '-', @cols), scalar(keys %l), @cols), "\n" }
