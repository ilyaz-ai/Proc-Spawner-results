#!/usr/bin/perl
# regroup.pl TABLES MATCH.tsv > ROWS.txt: the rows of the regrouped table (2026-11-21), from the tables of
# proc-spawner/2026-11-19-post-0.12-wine (cmp-WAY.txt, cls-WAY.tsv, chance-here-WAY.tsv) and Proc-Spawner's
# doc/large-subset/tools/large-subset-match.tsv (the snippets the project's Linux runs found to be chance, column why,
# or never ending, column shells = timeout).  Writes TABLES/rows-WAY.tsv (id, row, rule of cls-WAY.tsv, why) too.
# A snippet with a different result gets the first row that fits (rows of 2026-11-21, second form):
#   L  Linux itself gives no stable result: listed as chance or never ending by the project, or Proc::ShellSpawn's
#      result differs between Linux runs of the same setup in any record (TABLES/linux-varies.tsv, linux-varies.sh,
#      when it is there; else only the 4 Linux runs made where Windows ran, chance-here-WAY.tsv), in either way;
#      L does not depend on the way: every such snippet is in L in both ways, also one whose first Windows run gave
#      the same result as Linux (it is then taken out of same or paths, rule "same" or "same-paths" in rows-WAY.tsv);
#   M  the same as the Linux runs made on the machine Windows ran on (C-MACHINE: the base run's machine was set up
#      otherwise); counted with "same" in the table, as same+M;
#   (2026-11-21, third form: S1 only the Linux runner limits the size of files, H-NOFSIZE; S2 the other H- rules, the
#   test setup otherwise, as the recorders on Linux's PATH; S3 the environment, below)
#   S4 under Wine, MSYS2's fork does not work (H-NOFORK; Git's xargs hangs when it starts a command)
#   S3 environment variables the Windows runs had and the Linux runs did not (runwine.pl gives every Windows process
#      SystemRoot, PATHEXT, ..., USERNAME, TMP, TEMP, ...): H-ENV, W-USERNAME, and $TMP (NB:7037);
#   S1 the test runner under Wine (the other H- rules);
#   OS (a) Windows behaves otherwise (the other W- rules of the operating system; and H-ELF, an absolute path to a Linux
#      program, which Windows does not have, and H-WINEFS, the whole file system listed, which is another on Windows);
#   D  (b) Proc::ShellSpawn's own design for Windows (W-PWD, W-UMASK, W-ULIMIT, W-BACKSLASH, W-WINPATH of type ls);
#   P  (c) Perl's own system on Windows (P-);
#   G  (e) Git for Windows' programs differ from Linux's (G-: with -winreal, PortableGit's programs);
#   X  (f) a known bug of Proc::ShellSpawn (B-: X71);
#   U  not explained (U-: read one by one, cause not found);
#   WV (d) the result changes from run to run on Windows only (the rest of C- and T-).
use strict; use warnings;
my ($T, $M) = @ARGV; my (%chance, %never);
open my $m, '<', $M or die; while (<$m>) { next if /^#/; my @f = split /\t/; $chance{$f[0]} = 1 if $f[6] eq 'chance'; $never{$f[0]} = 1 if $f[3] eq 'timeout' }
my %DESIGN = map +($_ => 1), qw(W-PWD W-UMASK W-ULIMIT W-BACKSLASH);
my %DESIGN_ID = ('SC:Checks/ShellSupport.hs:prop_checkBashisms72' => 1);   # type ls: the path PATHEXT's lookup found
my %ENVR = map +($_ => 1), qw(H-ENV W-USERNAME); my %ENV_ID = ('NB:7037' => 1);   # rm -fR "${TMP}/"
# After the rerun without USERNAME and TMP (2026-11-21, tables/after-s2-rerun): these environment listings differ only
# in PATH (Windows' form) and PATHEXT, which Windows needs, and WINEUNIXCP, Wine's own: (a), as on real Windows too
my %ENV_WIN = map +($_ => 1), qw(NB:4934 NB:4935 NB:4940 NB:9232 NB:5100 NB:5101 NB:5102);
my @ROWS = qw(M L S1 S2 S3 S4 OS D P G X WV U); my (%n, %same, %paths, %all);
my %lv; if (open my $v, '<', "$T/linux-varies.tsv") { while (<$v>) { my ($id) = split /\t/; $lv{$id} = 1 } }
for my $w (qw(posix_spawn system1)) { open my $h, '<', "$T/chance-here-$w.tsv" or die; <$h>; while (<$h>) { chomp; my @f = split /\t/; $lv{$f[0]} = 1 if $f[2] > 1 } }
my %VARIES = map +($_ => 1), keys %chance, keys %never, keys %lv; my %seen;
for my $w (qw(posix_spawn system1)) {
  open my $c, '<', "$T/cmp-$w.txt" or die; while (<$c>) { $same{$w} = $1 if /^same +(\d+)/; $paths{$w} = $1 if /^same-paths +(\d+)/; $all{$w} = $1 if /^compared +(\d+)/ }
  open my $o, '>', "$T/rows-$w.tsv" or die; print $o "id\trow\trule\twhy\n";
  open my $s, '<', "$T/cls-$w.tsv" or die; <$s>; while (<$s>) { chomp; my ($id, $cl, $r) = split /\t/;
    my ($row, $why) = $chance{$id} ? ('L', 'project: chance') : $never{$id} ? ('L', 'project: never ends')
      : $lv{$id} ? ('L', 'Linux runs differ') : $r eq 'C-MACHINE' ? ('M', '') : $ENV_WIN{$id} ? ('OS', '') : ($ENVR{$r} || $ENV_ID{$id}) ? ('S3', '') : ($r eq 'H-ELF' || $r eq 'H-WINEFS') ? ('OS', '') : $r =~ /^W-/ ? (($DESIGN{$r} || $DESIGN_ID{$id}) ? 'D' : 'OS', '')
      : $r =~ /^P-/ ? ('P', '') : $r eq 'H-NOFSIZE' ? ('S1', '') : $r eq 'H-NOFORK' ? ('S4', '') : $r =~ /^H-/ ? ('S2', '') : $r =~ /^G-/ ? ('G', '') : $r =~ /^B-/ ? ('X', '') : $r =~ /^U-/ ? ('U', '') : ('WV', '');
    $n{$w}{$row}++; $n{$w}{"$row:$r"}++; $n{$w}{"$row why:$why"}++ if $why; print $o "$id\t$row\t$r\t$why\n"; $seen{$w}{$id} = 1 }
  # the snippets known to vary on Linux whose first Windows run gave the Linux result: in L too
  my %sp; open my $cp, '<', "$T/cmp-$w.tsv" or die; while (<$cp>) { next if /^#/; my ($id, $cl) = split /\t/; $sp{$id} = 1 if $cl eq 'same-paths' }
  for my $id (sort grep !$seen{$w}{$_}, keys %VARIES) {
    my ($r, $why) = ($sp{$id} ? 'same-paths' : 'same', $chance{$id} ? 'project: chance' : $never{$id} ? 'project: never ends' : 'Linux runs differ');
    $sp{$id} ? $paths{$w}-- : $same{$w}--; $n{$w}{L}++; $n{$w}{"L:$r"}++; $n{$w}{"L why:$why"}++; print $o "$id\tL\t$r\t$why\n" } }
printf "%-40s %11s %11s\n", 'row', 'posix_spawn', 'system1';
printf "%-40s %11d %11d\n", 'same', $same{posix_spawn}, $same{system1};
printf "%-40s %11d %11d\n", 'paths', $paths{posix_spawn}, $paths{system1};
printf "%-40s %11d %11d\n", $_, $n{posix_spawn}{$_} // 0, $n{system1}{$_} // 0 for @ROWS;
printf "%-40s %11d %11d\n", 'all', $all{posix_spawn}, $all{system1};
for my $w (qw(posix_spawn system1)) { my $t = $same{$w} + $paths{$w}; $t += $n{$w}{$_} // 0 for @ROWS; print "check $w: ", ($t == $all{$w} ? 'ok' : "WRONG $t"), "\n" }
print "\nby row and rule (or why):\n";
my %k; $k{$_} = 1 for map keys %{$n{$_}}, qw(posix_spawn system1);
printf "%-40s %11d %11d\n", $_, $n{posix_spawn}{$_} // 0, $n{system1}{$_} // 0 for sort grep /[: ]/, keys %k;
print "\nwhere the snippets of a row in one way are in the other (rows of the other way; same: the same or paths there):\n";
my %row; for my $w (qw(posix_spawn system1)) { open my $i, '<', "$T/rows-$w.tsv" or die; <$i>; while (<$i>) { my ($id, $r) = split /\t/; $row{$w}{$id} = $r } }
for my $pair (['posix_spawn', 'system1'], ['system1', 'posix_spawn']) { my ($a, $b) = @$pair; my %x;
  for my $id (keys %{$row{$a}}) { my $o = $row{$b}{$id} // 'same'; $x{"$row{$a}{$id} -> $o"}++ if $o ne $row{$a}{$id} }
  printf "%s -> %s: %s\n", $a, $b, join(', ', map "$_ $x{$_}", sort keys %x) }
