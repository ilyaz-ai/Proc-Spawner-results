#!/usr/bin/perl
# show.pl LINUXDIR WINDIR ID...: each sample's differing parts, Linux then Windows (raw, cut at 300 characters)
use strict; use warnings; use JSON::PP; binmode STDOUT, ':utf8';
my ($LD, $WD, @ids) = @ARGV; my %want = map +($_ => 1), @ids;
sub load { my %h; for my $f (map glob("$_/run-*.jsonl"), split /,/, $_[0]) { open my $i, '<', $f or die; while (<$i>) { next unless /"id":"([^"]*)"/ && $want{$1}; my $r = decode_json($_); $h{$r->{id}} = $r } } \%h }
my $L = load($LD); my $W = load($WD);
for my $id (@ids) { my ($l, $w) = ($L->{$id}{ours}, $W->{$id}{ours}); print "== $id: ", substr($W->{$id}{text}, 0, 150) =~ s/\n/ /gr, "\n";
  for my $k (qw(status out err rec files after)) { next if ($l->{$k} // '') eq ($w->{$k} // '');
    for ([L => $l], [W => $w]) { my $t = substr($_->[1]{$k} // '', 0, 300); $t =~ s/\n/\\n/g; $t =~ s/\037/|/g; $t =~ s/\036/^/g; print "  $k $_->[0]: $t\n" } } }
