#!/usr/bin/perl
# summary.pl [DIR]: the counts of the results section, from DIR's cmp-WAY.txt and cls-WAY.tsv (WAY posix_spawn, system1).
# Rows: the same; (a) W-, (b) P-, (c) H-, (d) C-MACHINE, (e) C-CHANCE and C-VARIES, (f) T-; the same apart from paths.
use strict; use warnings;
my $D = shift // '.'; my @W = qw(posix_spawn system1);
my %row = (W => 'a', P => 'b', H => 'c', T => 'f'); my (%n, %msg, %ids, %rule);
for my $w (@W) {
  open my $c, '<', "$D/cmp-$w.txt" or die; while (<$c>) { $n{$w}{same} = $1 if /^same +(\d+)/; $n{$w}{paths} = $1 if /^same-paths +(\d+)/; $n{$w}{all} = $1 if /^compared +(\d+)/ }
  open my $s, '<', "$D/cls-$w.tsv" or die; <$s>; while (<$s>) { chomp; my ($id, $cl, $r) = split /\t/;
    my $g = $r eq 'C-MACHINE' ? 'd' : $r =~ /^C-/ ? 'e' : $row{substr $r, 0, 1} // '?';
    $n{$w}{$g}++; $n{$w}{diff}++; $msg{$w}{$g}++, $msg{$w}{diff}++ if $cl eq 'msg'; $ids{$w}{$r}{$id} = 1; $rule{$r}{$w}++ } }
printf "%-28s %12s %12s\n", 'row', @W;
for my $k (qw(same a b c d e f diff paths all)) { printf "%-28s %12s %12s\n", $k, map { ($n{$_}{$k} // 0) . ($k =~ /^[a-f]$|diff/ ? sprintf(" (msg %d)", $msg{$_}{$k} // 0) : '') } @W }
printf "check: same + diff + paths = all: %s\n", join ' ', map { $n{$_}{same} + $n{$_}{diff} + $n{$_}{paths} == $n{$_}{all} ? 'ok' : 'WRONG' } @W;
print "\nper rule:\n";
printf "%-18s %5d %5d\n", $_, $rule{$_}{posix_spawn} // 0, $rule{$_}{system1} // 0 for sort keys %rule;
print "\nin both ways (the same snippets):\n";
for my $r (sort keys %rule) { my @b = grep $ids{system1}{$r}{$_}, keys %{$ids{posix_spawn}{$r} // {}}; printf "%-18s %5d\n", $r, scalar @b if @b }
my %e; for my $w (@W) { $e{$w} = { map { $_ => 1 } map keys %{$ids{$w}{$_} // {}}, qw(C-CHANCE C-VARIES) } }
printf "(e) in both ways: %d; posix_spawn only: %s; system1 only: %s\n", scalar(grep $e{system1}{$_}, keys %{$e{posix_spawn}}),
  join(' ', sort grep !$e{system1}{$_}, keys %{$e{posix_spawn}}), join(' ', sort grep !$e{posix_spawn}{$_}, keys %{$e{system1}});
