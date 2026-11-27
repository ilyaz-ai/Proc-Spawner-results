#!/usr/bin/perl
# classify.pl [-chance CHANCE.tsv] [-machine IDS] LINUXDIR WINDIR CMP.tsv > CLASSES.tsv: each sample wincompare.pl did not find
# "same" (nor same-paths), with the first rule that explains its difference (column rule) and every other rule that
# matches too (column also).  W-: Windows behaviour of ours; P-: Perl's own; H-: the harness (Wine, the bridge, the
# recorder), not ours; T-: a timeout; ?: none fits.
# -machine IDS: C-MACHINE, before C-CHANCE, for these samples (the base run differs from Linux runs repeated on this
#   machine, which agree with each other and with some Windows run).
# -chance (chance.pl's output, from repeats of the same environment): C-CHANCE, before the rules, when some run of
#   one side gives the same result as some run of the other (so no steady difference); C-VARIES, after the rules,
#   when a side varies and never agrees with the other.  Without it: N-NOISY, wincompare.pl's noisy mark (the two
#   ways' Linux runs differ: not a repeat of the same environment, kept only for the first tables).
use strict; use warnings; use JSON::PP; use Getopt::Long;
my ($CHANCE, $MACHINE); GetOptions('chance=s' => \$CHANCE, 'machine=s' => \$MACHINE) && @ARGV == 3 or die "usage\n";
my ($LD, $WD, $CMP) = @ARGV;
my %MACH; if ($MACHINE) { open my $i, '<', $MACHINE or die "$MACHINE: $!"; %MACH = map { chomp; ($_ => 1) } <$i> }
my %CH; if ($CHANCE) { open my $i, '<', $CHANCE or die "$CHANCE: $!"; <$i>; while (<$i>) { chomp; my @f = split /\t/; $CH{$f[0]} = \@f } }
sub paths { my $t = shift // '';   # Windows' paths written as Linux's.  2026-11-21: in quotes, MSYS's programs double a
  # backslash; and GNU programs quote a file name in some messages, MSYS's also where it holds a \: quotes around an
  # absolute path are taken off, on both sides alike
  $t =~ s{'([Zz]:[^'\n]*)'}{ (my $q = $1) =~ s/\\\\/\\/g; "'$q'" }ge;
  $t =~ s{[Zz]:((?:[\\/][^\s|"'`:;,()<>\037\036]*)+)}{ (my $p = $1) =~ tr{\\}{/}; $p }ge;
  $t =~ s{'(/[^'\n]*)'}{$1}g; $t }
# a directory may be DIR1,DIR2,...: a later one's record replaces an earlier one's; each record knows its directory (_dir)
sub load { my %h; for my $d (split /,/, $_[0]) { for my $f (glob "$d/run-*.jsonl") { open my $i, '<', $f or die; while (<$i>) { my $r = eval { decode_json($_) } or next; $r->{_dir} = $d; $h{$r->{id}} = $r } } } \%h }
# runs whose sample text was written as UTF-8 (runwine.pl from 2026-11-19; wine.txt says so)
my %FIXED; for my $d (split /,/, $WD) { open my $t, "<", "$d/wine.txt" or next; local $/; $FIXED{$d} = 1 if <$t> =~ /written as UTF-8/ }
my $L = load($LD); my $W = load($WD);
# the way of the Windows run (its wine.txt): a %MANUAL key ID@WAY holds for that way only
my $WAY = "posix_spawn"; for my $d (split /,/, $WD) { open my $t, "<", "$d/wine.txt" or next; local $/; $WAY = "system1" if <$t> =~ /primitive: system1/ }
# Read one by one (posix_spawn, 2026-11-18): samples no rule explains
my %MANUAL = (
  'NB:11148' => 'W-DIRREDIR',        # find <dir ...: a directory opened as input fails on Windows (Linux: opens)
  'NB:12249' => 'W-NULDEV',          # 2>/dev/nul: a name ending in "nul" is the NUL device on Windows (Linux: cannot create)
  'NB:3440'  => 'H-TMPSTATE',        # >> /tmp/size.log: on Linux another worker's user had made it (cannot create)
  'NB:3956'  => 'H-TMPSTATE',        # tee /tmp/allfiles: the same
  'NB:1831'  => 'W-NOLDSO',          # LD_PRELOAD: ld.so complains on Linux; nothing reads it on Windows
  'NB:3805'  => 'H-WINEFS',          # /home/*/: Wine does not list /home/ubuntu (mode 750, not ours)
  'SC:Checks/Commands.hs:prop_checkCatastrophicRm4' => 'H-WINEFS',   # /home/*: the same
  'SC:Checks/Commands.hs:prop_checkCatastrophicRm6' => 'H-WINEFS',   # /etc/*: Wine lists /etc otherwise
  'NB:4909'  => 'H-NOSIGPIPE',       # xargs: ls: terminated by signal 13 on Linux; no signals through the bridge
  'NB:7365'  => 'H-NOSIGPIPE',       # the same (xargs: echo)
  'NB:9731'  => 'H-NOSTREAM',        # tail -F | tee &: the bridge waits for tail's end before tee starts
  'NB:5776'  => 'H-NOSTREAM',      # { echo; cat bar; } | tee bar: a race on Linux; behind the bridge tee starts after cat has ended (steady)
  'NB:6335@posix_spawn' => 'G-FD3',   # comm /dev/fd/3: with Git's comm (-winreal, 2026-11-21) descriptor 3 is not seen; with the bridge it was H-DEVFD           # comm /dev/fd/3: the bridge passes descriptors 0-2 only
  'NB:9681'  => 'H-DEVFD',           # readlink /proc/self/fd/1: the bridge's own output file
  'NB:9672'  => 'H-DEVFD',           # tee /dev/stderr: on Linux it reopens (truncates) the run's err file; behind the bridge its own
  'NB:6790'  => 'W-ARGMAX',          # ldd /bin/* /usr/bin/*: Argument list too long (Windows: 32767 characters)
  'NB:6924'  => 'W-ARGMAX',
  'SC:Checks/ShellSupport.hs:prop_checkBashisms129' => 'W-STICKY', 'SC:Checks/ShellSupport.hs:prop_checkBashisms130' => 'W-STICKY',   # test -k /tmp: no sticky bit on Windows (status 1)
  'NB:6790@system1' => 'P-ENOENT', 'NB:6924@system1' => 'P-ENOENT',   # system1: Perl reports the failure (the line over 32767) as ENOENT: "ldd: not found" (doc/perl-win32-system-bugs.md, report 6)
  'SC:Checks/Commands.hs:prop_checkSourceArgs2' => 'H-DOTSOURCE',   # . script: on Linux PATH holds the recorder (a shell script) named script, which . reads
  'SC:Checks/ShellSupport.hs:prop_checkBashisms19' => 'W-FILENAME',  # > file*.txt: no * in Windows file names
  'SC:Checks/ShellSupport.hs:prop_checkBashisms69' => 'W-UMASK',     # umask -S: 0000 on Windows
  'TL:common/umask.md:12' => 'W-UMASK', 'TL:common/umask.md:8' => 'W-UMASK',
  'NB:5128' => 'W-PWD',             # pwd | cut -b2-: Z:/... less its first character
  'TL:common/curl.md:26' => 'W-CASE', 'TL:common/ppmtomitsu.md:16' => 'W-CASE',   # PATCH runs patch.exe, AS as.exe
  'TL:common/ulimit.md:13' => 'W-ULIMIT', 'TL:common/ulimit.md:17' => 'W-ULIMIT', 'TL:common/ulimit.md:25' => 'W-ULIMIT',   # ulimit -n, -c: not supported on Windows
  'NB:10550' => 'H-TMPSTATE',       # > /tmp/a: on Windows (system1) another worker's user had made it
  'NB:11568@system1' => 'P-ARGV',          # with -utf8 also W-ACP (the "…" read in code page 1252): both
  'TL:common/7za.md:29@posix_spawn' => 'H-RECLOG',   # in its first run, tar's log line overwrote gzip's (an empty line left): Wine's FILE_APPEND_DATA is not atomic between processes (2026-11-21)
  'NB:5764@system1' => 'P-ARGV',
  'NB:9051' => 'B-X71',   # kill -s WINCH $$: on Windows kill ... $$ goes to the program kill (known issue X71, ours); with Git's kill: "No such process" for Perl's Windows process ID
  'NB:7365@posix_spawn' => 'H-NOFORK', 'NB:7365@system1' => 'H-NOFORK',   # find | xargs echo rm | ksh -s: with Git's programs out of the 5 seconds on Windows: Git's xargs hangs when it starts a command (MSYS2's fork under Wine; find -exec: Bad address); 2026-11-21          # system1: awk gets FNR<4 {print >>"file"; close("file")} split at blanks, the " dropped (read 2026-11-21; H-NOSTREAM matched only the word yes)
  'NB:3699@system1' => 'P-ARGV',          # system1: also (first) W-WINPATH: readlink of a Z:/ path fails behind the bridge, so grep -v gets another pattern
);
my %MDESC = ('W-DIRREDIR' => 'a directory as input (< dir) fails on Windows', 'W-NULDEV' => 'a file name ending in nul is the NUL device',
  'H-TMPSTATE' => '/tmp held a file of another user on Linux', 'W-NOLDSO' => 'no ld.so (LD_PRELOAD)', 'H-NOSIGPIPE' => 'no SIGPIPE through the bridge',
  'H-DEVFD' => '/dev/fd, /proc/self/fd, /dev/stderr behind the bridge', 'W-ARGMAX' => 'the command line limit (32767)', 'H-NOFSIZE' => 'the Windows test runner sets no limit on the size of output files, which the Linux runner sets (Linux: status 153, SIGXFSZ; Windows: out of the 5 seconds)', 'G-FD3' => 'Git\'s programs do not see a descriptor above 2 passed the Windows way (win_spawn.h)', 'B-X71' => 'known issue X71 (ours): on Windows kill ... $$ goes to the program kill', 'U-UNEXPLAINED' => 'read one by one, cause not found', 'H-NOFORK' => 'under Wine, MSYS2\'s fork does not work: Git\'s xargs hangs when it starts a command, find -exec fails (Bad address)', 'H-RECLOG' => 'two stand-ins wrote their log lines at the same offset: under Wine 9.0 FILE_APPEND_DATA is not atomic between processes', 'W-STICKY' => 'no sticky bit on Windows: test -k is false', 'P-ENOENT' => 'Perl\'s own system on Windows (system1) reports every failure to start a program as ENOENT: a command line over the limit (32767) gives "not found" (doc/perl-win32-system-bugs.md, report 6)',
  'H-DOTSOURCE' => '. NAME found a recorder script on Linux', 'W-FILENAME' => 'characters Windows file names cannot hold',
  'W-UMASK' => 'umask is 0000 on Windows', 'W-ULIMIT' => 'ulimit -n, -c not supported on Windows');
# the programs runwine.pl really runs on Linux behind a stand-in (its %REAL)
my %REAL = map +($_ => 1), qw(echo printf test [ true false pwd kill cat grep egrep fgrep sed awk sort head tail wc tr cut uniq seq expr basename
  dirname printenv env xargs tee ls mkdir touch cmp diff od rev nl paste join fold comm tac realpath readlink stat sha256sum md5sum base64 yes);
my @rules = (
  ['H-NONASCII', 'non-ASCII text: a text of Latin-1 characters only reached ours as Latin-1 bytes, not UTF-8 (runwine.pl before 2026-11-19; redone)', sub { $_[0]{text} =~ /[^\x00-\x7f]/ && !$FIXED{$_[0]{_dir}} }],
  ['W-ACP', 'a byte string is taken in the ANSI code page (1252): a program reading wide arguments gets UTF-8 bytes as CP1252 characters', sub { my ($s, $l, $w) = @_; my $srt = sub { join "\n", sort split /\n/, shift }; $l->{rec} =~ /[\x80-\xff]/ && $srt->($w->{rec}) eq $srt->(acp_utf8($l->{rec})) }],
  ['P-ARGV', 'Perl\'s own spawn (system1) does not quote an argument holding a double quote, an empty one or one ending in a backslash as Windows splits it back (doc/perl-win32-system-bugs.md, bug 1): the program gets other arguments', sub { my ($s, $l, $w) = @_; my $wrec = paths($w->{rec});   # (Windows paths as Linux's: W-WINPATH may come with it)
     my %wr = map +($_ => 1), split /\n/, $wrec; my @miss = grep !$wr{$_}, split /\n/, paths($l->{rec});
     # the same words once quotes and backslashes are dropped and arguments joined by blanks
     my $nm = sub { (my $t = shift) =~ tr/"\\//d; $t =~ s/[\037\036 ]+/ /g; $t =~ s/^ | \z//g; $t }; my %wn = map +($nm->($_) => 1), split /\n/, $wrec;
     @miss && !grep !/"|\037\037|\037\z|\\(?:\037|\z)/ || !$wn{$nm->($_)}, @miss }],
  ['P-SYS1FD', 'Perl\'s own system on Windows (system1) passes a program only descriptors 0-2: a redirection of 3 and up is refused ("Invalid function.", 126)', sub { ($_[2]{err} . $_[2]{out}) =~ /: Invalid function\.$/m }],
  ['G-KILL', 'Git for Windows\' kill (-winreal) words its messages otherwise than Linux\'s procps kill (illegal pid: X, against failed to parse argument: \'X\'; No such process), and kill -l lists the signals otherwise', sub { my ($s, $l, $w) = @_; $s->{text} =~ /(?:^|[\s;&|(`])kill\b/ && $w->{rec} !~ /^kill\037/m && ($w->{err} . $w->{out}) =~ /^kill: |\bHUP INT QUIT\b/m }],
  ['W-LSMETA', 'ls -l of Windows\' file system (Git\'s ls): owner VM+USER, a numeric group, link count 1, directory size 0', sub { $_[2]{out} =~ /^[-dl][-rwxst]{9} +\d+ VM\+\S+ \d{6,} /m }],
  ['H-KILL2', 'kill of a process ID ($$, `pgrep ...`): logged and bridged on Windows, where the Linux kill does not know the Windows process', sub { $_[0]{text} =~ /\bkill\b/ && $_[2]{rec} =~ /^kill\037/m }],
  ['H-KILL', 'kill: quiet (not logged) on Linux, logged and bridged on Windows', sub { my ($s, $l, $w) = @_;
     $w->{rec} =~ /^kill(?:\037|$)/m or return; (my $wr = $w->{rec}) =~ s/^kill(?:\037[^\n]*)?\n//mg; (my $we = $w->{err}) =~ s{/runcompare/real/kill:}{kill:}g; $wr eq $l->{rec} && $we eq $l->{err} && $w->{out} eq $l->{out} }],
  ['H-ELF', 'an absolute path to a Linux program (/usr/bin/x, /bin/sh): ours cannot start an ELF, 126 (real Windows: not found)', sub { $_[2]{err} =~ m{(?:^|: )/(?:usr/)?s?bin/\S+: Permission denied}m }],
  ['H-ENV', 'the environment listed or searched: Windows has its own variables (ComSpec, ...), the bridge its PATH', sub { $_[0]{text} =~ /(?:^|[\s|;&(`])(?:env|printenv|set|export\s+-p|declare\s+-[px]|compgen)(?:\s*(?:$|[|;&>)`])|\s+(?:-0|\||-u))/m || $_[0]{text} =~ /\benv\s*\|/ }],
  ['H-NOSTREAM', 'a program that writes forever (yes, cat /dev/zero, ...): the bridge reads its input to the end first; no SIGPIPE', sub { $_[0]{text} =~ /\byes\b|\/dev\/(?:u?random|zero)|\bseq\s+inf/ }],
  ['H-WINEFS', 'the whole file system listed: Wine\'s own files (/tmp/wine-*), /sys, /proc, the prefixes', sub { my ($s, $l, $w) = @_; ($w->{rec} . $w->{out} . $w->{err}) =~ m{/tmp/wine-|/runwin} || $s->{text} =~ m{(?:find|ls|du)\s[^|;]*(?:\s/\s|\s/$|/tmp/\*|/\[|\s/\*)}m }],
  ['H-DOTDOT', 'ls -l of the run directory: its parent (the worker directory) has another date and link count', sub { my ($s, $l, $w) = @_; my @a = grep !/ \.\.$/, split /\n/, $l->{out}; my @b = grep !/ \.\.$/, split /\n/, $w->{out}; "@a" eq "@b" && $l->{out} ne $w->{out} }],
  ['H-WCPAD', 'wc (or similar) pads its counts otherwise when its input is a file (the bridge) than a pipe', sub { my ($s, $l, $w) = @_; (my $a = $l->{out}) =~ s/[ \t]+/ /g; (my $b = $w->{out}) =~ s/[ \t]+/ /g; s/^ //mg for $a, $b; $a eq $b && $l->{out} ne $w->{out} }],
  ['W-PATHSEP', '$PATH joined by ";" on Windows', sub { $_[0]{text} =~ /\$\{?PATH\b/ }],
  ['W-USERNAME', 'USERNAME is set on Windows', sub { $_[0]{text} =~ /\$\{?USERNAME\b/ }],
  ['H-WINPATH', 'a Windows path (~, $HOME, $PWD, pwd: Z:\\...) given to a Linux program behind a stand-in (mkdir, ls, cat, grep, readlink, ...), which cannot open it; a Windows program would', \&hwinpath],
  ['W-WINPATH', 'a Windows path or name where Linux has its own, beyond the path alone (type ls: Z:\\...\\ls.EXE; $TMP, set on Windows)', sub { my ($s, $l, $w) = @_; my $t = join '', @$w{qw(rec err out files)}; $t =~ /[Zz]:[\\\/]/ && !hwinpath(@_) }],
  ['W-PWD', 'pwd gives a Windows path (Z:/...)', sub { $_[0]{text} =~ /\bpwd\b|\$\{?PWD\b/ && $_[2]{out} =~ /^Z:/m }],
  ['W-CASE', 'program lookup ignores case (PATCH runs patch.exe)', sub { my ($s, $l, $w) = @_; my @nf = $l->{err} =~ /(?:^|: )([A-Za-z][\w.-]*): not found/mg; grep { my $n = $_; $n ne lc $n && $w->{rec} =~ /^\Q${\ lc $n}\E(?:\037|\n|$)/mi } @nf }],
  ['W-BACKSLASH', 'a command word "\\" names the root directory: 126 (Linux: 127 not found)', sub { $_[2]{err} =~ /(?:^|: )\\: Permission denied/m }],
);
open my $c, '<', $CMP or die; my %n; my %also;
print join("\t", qw(id class rule parts noisy also text)), "\n";
while (<$c>) { next if /^#/; chomp; my ($id, $class, $parts, $noisy, $text) = split /\t/;
  next if $class =~ /^same/;
  my ($s, $l, $w) = ($W->{$id}, $L->{$id}{ours}, $W->{$id}{ours}); my $ch = $CH{$id};
  my @match = map $_->[0], grep $_->[2]->($s, $l, $w), @rules; my $man = $MANUAL{"$id\@$WAY"} // $MANUAL{$id}; unshift @match, $man if $man;   # a snippet read by hand: its verdict first (2026-11-21)
  my $rule = $class eq 'timeout-win' && ($l->{status} // '') eq '153' ? 'H-NOFSIZE' : $man ? $man : $class =~ /^timeout/ ? "T-$class" : $MACH{$id} ? 'C-MACHINE' : $ch && $ch->[5] ? 'C-CHANCE' : $match[0] // '?';   # (a hand-read verdict before chance: 2026-11-21)
  if ($rule eq '?') { $rule = $ch ? ($ch->[2] > 1 || $ch->[4] > 1 ? 'C-VARIES' : '?') : $noisy ? 'N-NOISY' : '?' }
  my @also = grep $_ ne $rule, @match;
  $n{$rule}++; $also{$_}++ for @also;
  print join("\t", $id, $class, $rule, $parts, $noisy, join(',', @also), $text), "\n" }
my %desc = map +($_->[0] => $_->[1]), @rules; %desc = (%MDESC, %desc); $desc{'N-NOISY'} = 'differs between the two ways\' Linux runs too'; $desc{'?'} = 'not explained by a rule';
$desc{'C-MACHINE'} = 'the Linux run was made on another machine, whose system files differ (/etc/passwd, /usr/bin, ...): Linux repeated here gives one result, not the base run\'s, and some Windows run gives it too';
$desc{'C-CHANCE'} = 'some run on one side gives the same result as some run on the other: no steady difference';
$desc{'C-VARIES'} = 'varies from run to run on a side, never agrees with the other, no rule explains it';
printf STDERR "%5d %-12s %s\n", $n{$_}, $_, $desc{$_} // '' for sort { $n{$b} <=> $n{$a} || $a cmp $b } keys %n;
print STDERR "\nAlso matching (samples whose first category is another):\n" if %also;
printf STDERR "%5d %s\n", $also{$_}, $_ for sort { $also{$b} <=> $also{$a} || $a cmp $b } keys %also;
# bytes (as characters below 256) read in code page 1252, written as UTF-8 (bytes as characters): what a Windows program
# taking wide arguments logs (recorder-utf8.exe) for bytes passed through CP_ACP; 0x81 0x8D 0x8F 0x90 0x9D: as they are
sub acp_utf8 { require Encode; my $t = shift; my %u = map +(chr($_) => chr($_)), 0x81, 0x8D, 0x8F, 0x90, 0x9D;
  $t =~ s/([\x80-\xff])/$u{$1} \/\/ Encode::decode('cp1252', $1)/ge; Encode::encode_utf8($t) }
# H-WINPATH: a Linux program behind a stand-in (runwine.pl's %REAL) got a Windows path, or said so
sub hwinpath { my ($s, $l, $w) = @_;
  (grep { my ($n) = /^([^\037\n]*)/; $REAL{$n} && /[Zz]:[\\\/]/ } split /\n/, $w->{rec}) || $w->{err} =~ m{/runcompare/real/[^:\n]+: .*[Zz]:[\\/]} }
