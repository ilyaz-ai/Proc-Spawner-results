#!/usr/bin/perl
# wincompare.pl: ours on Windows (runwine.pl's OUTDIR) against ours on Linux (large-subset-runcompare.pl -shells ours's
# OUTDIR), sample by sample.
# Usage: perl wincompare.pl [-noise LINUX2DIR] [-l LIST.tsv] LINUXDIR WINDIR
# A directory may be DIR1,DIR2,...: their records together, a later one's replacing an earlier one's of the same sample.
# Compared as large-subset-runreport.pl -ours-vs compares: status, out, err (each shell's prefix taken off, then as a
# multiset of characters), rec (the calls, sorted), files (what the run's directory holds afterwards), after (A18).
# Classes, the first that fits:
#   same           equal as they are
#   same-paths     equal once Windows' paths are written as Linux's (Z:\x\y and Z:/x/y as /x/y)
#   same-crlf      equal once CR LF is LF
#   same-paths+crlf  both
#   msg            status, out, rec, files, after equal (after those two), the messages differ
#   timeout-both   both ran out of time (5 s)
#   timeout-win, timeout-linux   only one did
#   differs        beyond the messages (the parts are listed)
# -noise LINUX2DIR: a second Linux run of ours (here: through Run): a sample whose result differs between the two
#   Linux runs is marked noisy (process IDs, times, races), whatever its class.
# -l LIST.tsv: one line per sample not "same": id, class, parts, noisy, text excerpt, then each differing part
#   (normalized) as Linux / Windows excerpts.
use strict; use warnings; use JSON::PP; use Getopt::Long;
my ($NOISE, $LIST); GetOptions('noise=s' => \$NOISE, 'l=s' => \$LIST) && @ARGV == 2 or die "usage\n";
my ($LD, $WD) = @ARGV;
sub load { my %h; for my $f (map glob("$_/run-*.jsonl"), split /,/, $_[0]) { open my $i, '<', $f or die "$f: $!";
    while (<$i>) { my $r = eval { decode_json($_) } or next; $h{$r->{id}} = $r } } \%h }
my $L = load($LD); my $W = load($WD); my $N = $NOISE ? load($NOISE) : {};
sub msgs { my $t = shift // ''; $t =~ s/^(?:(?:\S*\/)?(?:dash|bash|sh): (?:\d+: |line \d+: )?)//mg; $t =~ s{^(?:/runcompare/real|/usr/bin)/([\w.+\[-]+): }{$1: }mg; join '', sort split //, $t }   # (2026-11-21: also the program's own path, the test setup's on both sides)
sub paths { my $t = shift // '';   # Windows' paths written as Linux's.  2026-11-21: in quotes, MSYS's programs double a
  # backslash; and GNU programs quote a file name in some messages, MSYS's also where it holds a \: quotes around an
  # absolute path are taken off, on both sides alike
  $t =~ s{'([Zz]:[^'\n]*)'}{ (my $q = $1) =~ s/\\\\/\\/g; "'$q'" }ge;
  $t =~ s{[Zz]:((?:[\\/][^\s|"'`:;,()<>\037\036]*)+)}{ (my $p = $1) =~ tr{\\}{/}; $p }ge;
  $t =~ s{'(/[^'\n]*)'}{$1}g; $t }
sub crlf { my $t = shift // ''; $t =~ s/\r\n/\n/g; $t }
sub view { my ($o, @n) = @_; my %v;
  for my $k (qw(status out err rec files after)) { my $t = $o->{$k} // ''; $t = $_->($t) for @n;
    $t = join "\n", sort split /\n/, $t if $k eq 'rec';
    $t = msgs($t) if $k eq 'err'; $v{$k} = $t } \%v }
sub diffparts { my ($a, $b) = @_; grep $a->{$_} ne $b->{$_}, qw(status out err rec files after) }
my %count; my %bysrc; my @lines; my $n = 0;
for my $id (sort keys %$W) {
  my $w = $W->{$id}{ours}; my $l = $L->{$id} && $L->{$id}{ours}; next unless $l; $n++;
  my $src = $id =~ /^(TL|NB|SC|BC|PS|PB)/ ? $1 : ($id =~ /^([^:]+)/)[0];
  my ($class, @parts);
  if ($w->{error}) { $class = 'runner-error'; @parts = ('error') }
  elsif ($l->{status} eq '124' || $w->{status} eq '124') {
    $class = $l->{status} eq '124' && $w->{status} eq '124' ? 'timeout-both' : $w->{status} eq '124' ? 'timeout-win' : 'timeout-linux' }
  else {
    my @tries = (['same'], ['same-paths', \&paths], ['same-crlf', \&crlf], ['same-paths+crlf', \&paths, \&crlf]);
    for my $t (@tries) { my ($c, @f) = @$t; my @d = diffparts(view($l, @f), view($w, @f)); unless (@d) { $class = $c; last } }
    unless ($class) { @parts = diffparts(view($l, \&paths, \&crlf), view($w, \&paths, \&crlf));
      $class = "@parts" eq 'err' ? 'msg' : 'differs' } }
  my $noisy = '';
  if (my $n2 = $N->{$id} && $N->{$id}{ours}) { $noisy = diffparts(view($l), view($n2)) ? 'noisy' : '' }
  $count{$class}++; $bysrc{$src}{$class}++;
  next if $class eq 'same' || !$LIST;
  my $ex = substr($W->{$id}{text}, 0, 120); $ex =~ s/[\t\n]/ /g;
  my @det; if (@parts) { my ($vl, $vw) = (view($l, \&paths, \&crlf), view($w, \&paths, \&crlf));
    for my $p (@parts) { my ($a, $b) = map { my $s = substr($_->{$p} // '', 0, 400); $s =~ s/\\/\\\\/g; $s =~ s/\n/\\n/g; $s =~ s/\r/\\r/g; $s =~ s/\t/\\t/g; $s =~ s/\037/|/g; $s =~ s/\036/^/g; $s } ($p eq 'err' ? ($l, $w) : ($vl, $vw));
      push @det, "$p: L=$a", "$p: W=$b" } }
  push @lines, join("\t", $id, $class, join(',', @parts), $noisy, $ex, @det) . "\n" }
my @cl = qw(same same-paths same-crlf same-paths+crlf msg differs timeout-both timeout-win timeout-linux runner-error);
printf "%-16s %7s\n", $_, $count{$_} // 0 for @cl; printf "%-16s %7d\n", 'compared', $n;
print "\nBy source:\n", join("\t", 'src', @cl), "\n";
print join("\t", $_, map $bysrc{$_}{$_[0]} // 0, @cl), "\n" for ();
for my $s (sort keys %bysrc) { print join("\t", $s, map($bysrc{$s}{$_} // 0, @cl)), "\n" }
if ($LIST) { open my $o, '>', $LIST or die; binmode $o, ":encoding(UTF-8)"; print $o "# id\tclass\tparts\tnoisy\ttext\tdetails (L: Linux, W: Windows; normalized, err as recorded)\n", @lines; close $o }
