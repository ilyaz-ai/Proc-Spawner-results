# rawdiff.pl LINUXDIR WINDIR [IDSFILE]: the samples where ours differs, field by field (first 300 characters)
use strict; use warnings; use JSON::PP;
my ($LD, $WD) = @ARGV; my %L;
for my $f (glob "$LD/run-*.jsonl") { open my $i, "<", $f or die; while (<$i>) { my $r = decode_json($_); $L{$r->{id}} = $r->{ours} } }
my ($n, $same) = (0, 0);
for my $f (sort glob "$WD/run-*.jsonl") { open my $i, "<", $f or die; while (<$i>) { my $r = decode_json($_); my $w = $r->{ours}; my $l = $L{$r->{id}} or next; $n++;
  my @d = grep { ($w->{$_}//"") ne ($l->{$_}//"") } qw(status out err rec files after error);
  $same++, next unless @d;
  print "== $r->{id}: ", substr($r->{text},0,100) =~ s/\n/\\n/gr, "\n";
  for (@d) { my ($a,$b) = map { substr($_//"",0,300) =~ s/\n/\\n/gr =~ s/\r/\\r/gr =~ s/\037/|/gr =~ s/\036/^/gr } $l->{$_}, $w->{$_}; print "  $_ L: [$a]\n  $_ W: [$b]\n" } } }
print "# $n compared, $same the same\n";
