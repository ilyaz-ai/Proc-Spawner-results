#!/usr/bin/perl
# (2026-11-21: found the one record with the overwrite mark: TL:common/7za.md:29, base/win-posix_spawn)
# scan2.pl LINUXDIR WINDIR...: Windows records whose log of calls has fewer lines than Linux's or an empty line, where the
# Linux record of the same snippet has none: the marks of two stand-ins writing at the same offset
use strict; use warnings; use JSON::PP;
sub lines { my $t = shift // ''; my @l = split /\n/, $t, -1; pop @l if @l && $l[-1] eq ''; @l }
sub load { my %h; for my $f (glob "$_[0]/run-*.jsonl") { open my $i, '<', $f or die; while (<$i>) { my $r = eval { decode_json($_) } or next; $h{$r->{id}} = $r->{ours}{rec} } } \%h }
my $L = load(shift);
for my $d (@ARGV) { my $W = load($d); my (@empty, @fewer);
  for my $id (sort keys %$W) { my @w = lines($W->{$id}); my @l = lines($L->{$id});
    push @empty, $id if (grep $_ eq '', @w) && !(grep $_ eq '', @l);
    push @fewer, $id if @w < @l && !(grep $_ eq '', @w) }
  printf "%-36s empty line: %d%s; fewer calls than Linux: %d\n", $d, scalar @empty, @empty <= 15 ? " (@empty)" : '', scalar @fewer }
