#!/usr/bin/perl
# strip-fastcwd.pl IN OUT (2026-11-21): copies the run records of IN (run-*.jsonl, wine.txt, ...) to OUT with every
# block of MSYS2's warning under Wine taken out of ours' out and err: "Cygwin WARNING:" and its 4 lines ending in
# "problems.html", and the empty line after it.  MSYS2's runtime (msys-2.0.dll, PortableGit) prints it at every start
# under Wine (it cannot find FAST_CWD in Wine's ntdll); real Windows prints nothing.  Counts what it took out.
use strict; use warnings; use JSON::PP; use File::Copy; use File::Path 'make_path';
my ($in, $out) = @ARGV; make_path($out); my ($recs, $blocks) = (0, 0);
my $re = qr/Cygwin WARNING:\n  Couldn't compute FAST_CWD pointer\.  This typically occurs if you're using\n  an older Cygwin version on a newer Windows\.  Please update to the latest\n  available Cygwin version from https:\/\/cygwin\.com\/\.  If the problem persists,\n  please see https:\/\/cygwin\.com\/problems\.html\n\n?/;
my $js = JSON::PP->new->canonical;
for my $f (glob "$in/*") { my $b = $f =~ s{.*/}{}r;
  if ($b !~ /^run-\d+\.jsonl\z/) { copy($f, "$out/$b") if -f $f; next }
  open my $i, '<', $f or die; open my $o, '>', "$out/$b" or die;
  while (my $l = <$i>) { my $r = decode_json($l); my $n = 0;
    for my $k (qw(out err)) { next unless defined $r->{ours}{$k}; $n += ($r->{ours}{$k} =~ s/$re//g) }
    $recs++ if $n; $blocks += $n; print $o $js->encode($r), "\n" } }
open my $w, '>>', "$out/wine.txt" or die; print $w "strip-fastcwd.pl: MSYS2's FAST_CWD warning taken out of ours' out and err: $blocks blocks in $recs records\n";
print "$in: $blocks blocks in $recs records\n";
