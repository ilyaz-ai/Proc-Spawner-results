#!/usr/bin/perl
# chance.pl -a RUN -a RUN ... -b RUN -b RUN ... > CHANCE.tsv: what varies from run to run, from repeats of the same
# environment.  Each RUN is one run's directory (or DIR1,DIR2: DIR2's records replacing DIR1's of the same sample);
# -a: the runs of one side (here: ours on Linux, one way), -b: of the other (ours under Wine, or the other way).
# For each sample that has records on both sides, one line:
#   id, runs of a, distinct results of a, runs of b, distinct results of b, overlap
# A result: status, out, err (the shell's prefix taken off, as a multiset of characters), rec (sorted), files, after,
# as wincompare.pl compares them.  "distinct" counts each side as it is; "overlap" is 1 when some run of a and some
# run of b give the same result once Windows' paths are written as Linux's and CR LF as LF (as wincompare.pl's
# same-paths), else 0: then the two sides never agreed in these runs.
use strict; use warnings; use JSON::PP; use Getopt::Long;
my (@A, @B); GetOptions('a=s' => \@A, 'b=s' => \@B) && @A && @B or die "usage\n";
sub load { my %h; for my $d (split /,/, $_[0]) { for my $f (glob "$d/run-*.jsonl") { open my $i, '<', $f or die "$f: $!";
    while (<$i>) { my $r = eval { decode_json($_) } or next; $h{$r->{id}} = $r->{ours} } } } \%h }
sub msgs { my $t = shift // ''; $t =~ s/^(?:(?:\S*\/)?(?:dash|bash|sh): (?:\d+: |line \d+: )?)//mg; $t =~ s{^(?:/runcompare/real|/usr/bin)/([\w.+\[-]+): }{$1: }mg; join '', sort split //, $t }   # (2026-11-21: also the program's own path, the test setup's on both sides)
sub paths { my $t = shift // '';   # Windows' paths written as Linux's.  2026-11-21: in quotes, MSYS's programs double a
  # backslash; and GNU programs quote a file name in some messages, MSYS's also where it holds a \: quotes around an
  # absolute path are taken off, on both sides alike
  $t =~ s{'([Zz]:[^'\n]*)'}{ (my $q = $1) =~ s/\\\\/\\/g; "'$q'" }ge;
  $t =~ s{[Zz]:((?:[\\/][^\s|"'`:;,()<>\037\036]*)+)}{ (my $p = $1) =~ tr{\\}{/}; $p }ge;
  $t =~ s{'(/[^'\n]*)'}{$1}g; $t }
sub crlf { my $t = shift // ''; $t =~ s/\r\n/\n/g; $t }
sub key { my ($o, @n) = @_; return "error:" . $o->{error} if $o->{error};
  join "\0\0", map { my $k = $_; my $t = $o->{$k} // ''; $t = $_->($t) for @n;
    $t = join "\n", sort split /\n/, $t if $k eq 'rec'; $t = msgs($t) if $k eq 'err'; $t } qw(status out err rec files after) }
my @a = map load($_), @A; my @b = map load($_), @B;
print join("\t", qw(id runs_a distinct_a runs_b distinct_b overlap)), "\n";
my %ids; $ids{$_}++ for map keys %$_, @a;
for my $id (sort keys %ids) {
  my @ra = grep defined, map $_->{$id}, @a; my @rb = grep defined, map $_->{$id}, @b; next unless @ra && @rb;
  my %da = map +(key($_) => 1), @ra; my %db = map +(key($_) => 1), @rb;
  my %na = map +(key($_, \&paths, \&crlf) => 1), @ra; my $ov = grep $na{key($_, \&paths, \&crlf)}, @rb;
  print join("\t", $id, scalar @ra, scalar keys %da, scalar @rb, scalar keys %db, $ov ? 1 : 0), "\n" }
