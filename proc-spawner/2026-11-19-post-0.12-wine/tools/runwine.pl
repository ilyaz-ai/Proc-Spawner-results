#!/usr/bin/perl
# runwine.pl: large-subset-runcompare.pl's run of ours alone, with ours under Wine (Strawberry Perl, the Windows build).
# Usage (root, under unshare -n): perl runwine.pl [-j 4] [-n MAX] [-only IDS|@FILE] [-run] [-user rc] [-base /runwin]
#        -dist WINBUILD -runpm RUN.PM -tools TOOLSDIR samples.jsonl samples.tsv OUTDIR
# The same fixture, environment (plus what Windows itself needs), -env mtime, 5-second timeout, A18's 5 seconds for
# what is left; the records in the same form (run-K.jsonl), so that large-subset-runreport.pl and the comparison read
# both.  Ours: perl.exe t/try.pl with the sample's text in TRY_FILE; -run: through Run (PROC_SPAWNER_MISSING="posix_spawn
# fork", system1).  Programs: NAME.exe (recorder.exe) for every name of large-subset-programs.txt; the %REAL ones run the
# Linux program through bridge.sh.  Each worker K: Linux user USERK, a Wine prefix of its own, one runner.exe.
use strict; use warnings; use JSON::PP; use File::Path qw(make_path remove_tree); use Cwd 'abs_path'; use Getopt::Long;
use IPC::Open2; use POSIX (); use Time::HiRes (); use Encode ();
my ($J, $MAX, $ONLY, $RUN, $UP, $BASE, $DISTW, $RUNPM, $TOOLS, $MTIME) = (4, 0, "", 0, "rc", "/runcompare", '', '', '', 1577836800);
my ($WORKERS, $NOSETUP, $UTF8, $LANGW, $ENVL) = ("", 0, 0, "C", "mtime");   # -lang: Wine's locale (LANG, LC_ALL)
my ($SETENV, $HIDE) = ('', '');   # -setenv NAME=VALUE (repeatable): a variable's value for every Windows process;
  # -hide LIST: variables t/try.pl deletes from its %ENV first (TRY_HIDE: those Wine adds, WINEUNIXCP, ...)
my @SETENV; my $NOENV = ''; my $BDROP = ''; my $BENVPATH = 0; my $WINREAL = '';   # -winreal DIR: Windows programs (PortableGit's usr/bin) in place of the Linux ones behind the bridge (recorder-winreal.exe)   # -bridge-env-path: see bridge.sh   # -bridge-drop REGEX: variables bridge.sh does not pass to the Linux program (WINE.*: Wine adds them to every process)   # -noenv LIST: variables left out of every Windows process's environment (2026-11-21: USERNAME,TMP)
my $WFROM = '';   # -workers-from DIR: each sample on the worker it had in that run (large-subset-runcompare.pl's option)
GetOptions('winreal=s' => \$WINREAL, 'bridge-env-path' => \$BENVPATH, 'bridge-drop=s' => \$BDROP, 'setenv=s' => \@SETENV, 'hide=s' => \$HIDE, 'noenv=s' => \$NOENV, 'workers-from=s' => \$WFROM, 'env=s' => \$ENVL, 'utf8' => \$UTF8, 'lang=s' => \$LANGW, 'workers=s' => \$WORKERS, 'nosetup' => \$NOSETUP, 'j=i' => \$J, 'n=i' => \$MAX, 'only=s' => \$ONLY, 'run' => \$RUN, 'user=s' => \$UP, 'base=s' => \$BASE,
  'dist=s' => \$DISTW, 'runpm=s' => \$RUNPM, 'tools=s' => \$TOOLS) && @ARGV == 3 && $DISTW && $TOOLS or die "usage\n";
my ($SJ, $ST, $OUT) = @ARGV; make_path($OUT); $OUT = abs_path($OUT);
$> == 0 or die "root\n";
# -env LIST: as large-subset-runcompare.pl's, of its variants mtime (always), tmp, random.  The project's runs use
# tmp,random,mtime.  tmp and random: each worker runs in a mount namespace of its own (the runner, Wine and the Linux
# programs behind the bridge all in it): tmp, a tmpfs on /tmp, /var/tmp and /dev/shm, emptied before every run but
# Wine's own server directory (/tmp/wine-XXXXXX: the long-lived runner needs it; on Linux a run's /tmp is empty);
# random, the runner's fixed file of 1 MiB over /dev/urandom and /dev/random.
my %ENV_ON = map +($_ => 1), split /,/, $ENVL;
for (keys %ENV_ON) { /^(?:mtime|tmp|random)\z/ or die "-env $_: only mtime, tmp, random\n" }
$ENV_ON{mtime} or die "-env: mtime is always on here; name it\n";
my $WIN = '/work/win';   # recorder.exe, runner.exe, bridge.sh
my $WB = "/runwin";   # the Wine prefixes (mkprefix.sh) and bridge.sh, whose path recorder.exe has built in
my $SP = 'Z:\\opt\\sp\\perl\\bin\\perl.exe';
sub zw { my $p = shift; $p =~ s{/}{\\}g; "Z:$p" }
make_path($BASE); chmod 0755, $BASE;
my $COPY = "$BASE/dist";
my $LIMIT = 4000;
my %QUIET = map +($_ => 1), qw(echo printf test [ true false pwd kill);
my %REAL = (%QUIET, map +($_ => 1), qw(cat grep egrep fgrep sed awk sort head tail wc tr cut uniq seq expr basename
  dirname printenv env xargs tee ls mkdir touch cmp diff od rev nl paste join fold comm tac realpath readlink stat
  sha256sum md5sum base64 yes));
unless ($NOSETUP) {   # -nosetup: BASE as another runwine.pl set it up (running at the same time; with -run it also holds Run.pm)
remove_tree($COPY); make_path("$COPY/t", "$COPY/run");
system('cp', '-a', "$DISTW/blib", $COPY) == 0 && system('cp', '-a', "$DISTW/t/try.pl", "$COPY/t/") == 0 or die "copy\n";
if ($RUN) { system('cp', '-a', $RUNPM, "$COPY/run/") == 0 or die "Run.pm\n" }
# Windows: bin (NAME.exe for every name), quiet (the QUIET ones but kill, which would take Windows process IDs for Linux ones)
# Linux, for the bridge: lbin (the Linux recorder), lquiet, real, as large-subset-runcompare.pl makes them
for (qw(bin quiet lbin lquiet real)) { remove_tree("$BASE/$_"); make_path("$BASE/$_") }
system("cp", "$WIN/recorder.exe", "$WIN/runner.exe", "$BASE/") == 0 or die;
# -utf8: the recorder that takes its arguments in wide characters, as UTF-8 (recorder.c with -DRECORDER_UTF8); -lang C.UTF-8: Wine
# itself under C.UTF-8 (under C it garbles non-ASCII arguments and file names between Linux and Windows)
if ($UTF8) { system("cp", "$WIN/recorder-utf8.exe", "$BASE/recorder.exe") == 0 or die }
if (length $WINREAL) { system("cp", "$WIN/recorder-winreal.exe", "$BASE/recorder.exe") == 0 or die }
my $rcsrc = do { open my $i, '<', "$TOOLS/large-subset-runcompare.pl" or die; local $/; <$i> };
my ($rec) = $rcsrc =~ /print \$r <<'SH'; close \$r; chmod 0755, "\$BASE\/rec";\n(.*?\n)SH\n/s or die "recorder text\n";
open my $r, '>', "$BASE/rec" or die; print $r $rec; close $r; chmod 0755, "$BASE/rec";
{ open my $b, '<', "$WIN/bridge.sh" or die; local $/; my $t = <$b>; $t =~ s/\@LPATH\@/$BASE\/lquiet:$BASE\/lbin/g; $t =~ s/\@REALDIR\@/$BASE\/real/g; $t =~ s/\@DROP\@/$BDROP/g; $t =~ s/\@ENVPATH\@/$BENVPATH ? 1 : ''/ge;
  open my $o, ">", "$WB/bridge.sh" or die; print $o $t; close $o; chmod 0755, "$WB/bridge.sh" }
open my $pl, '<', "$TOOLS/large-subset-programs.txt" or die; my %seen;
while (<$pl>) { chomp; next if /^#/ || !length || $seen{$_}++;
  link "$BASE/recorder.exe", "$BASE/bin/$_.exe" or die "$_: $!"; symlink "$BASE/rec", "$BASE/lbin/$_" or die }
for my $n (keys %REAL) { for my $d (qw(/usr/bin /bin)) { if (-x "$d/$n") { symlink "$d/$n", "$BASE/real/$n"; last } } }
for my $n (keys %QUIET) { symlink "$BASE/real/$n", "$BASE/lquiet/$n" if -e "$BASE/real/$n";
  link "$BASE/recorder.exe", "$BASE/quiet/$n.exe" or die if $n ne 'kill' }
if ($ENV_ON{random}) { require Digest::SHA; open my $o, '>:raw', "$BASE/random" or die;   # as large-subset-runcompare.pl's
  print $o Digest::SHA::sha256("x27-random-$_") for 0 .. 32767; close $o; chmod 0444, "$BASE/random" }
system('chmod', '-R', 'a+rX', $BASE) == 0 or die;
{ open my $e, '>', "$OUT/wine.txt" or die; print $e "ours under Wine ", `wine --version`, "primitive: ", ($RUN ? "system1 through Run (PROC_SPAWNER_MISSING=\"posix_spawn fork\")" : "as built (win_spawn.h)"), ($UTF8 ? "; -utf8: recorder-utf8.exe" : ""), "; Wine under LANG=$LANGW; the sample text written as UTF-8 (from 2026-11-19); -env ", join(',', sort keys %ENV_ON), ($NOENV ? "; -noenv $NOENV" : ""), map("; -setenv $_", @SETENV), (length $HIDE ? "; -hide $HIDE" : ""), (length $BDROP ? "; -bridge-drop $BDROP" : ""), ($BENVPATH ? "; -bridge-env-path" : ""), (length $WINREAL ? "; -winreal $WINREAL (recorder-winreal.exe)" : ""), "\n";
  require Digest::SHA; print $e "$_ sha256 ", Digest::SHA->new(256)->addfile($_)->hexdigest, "\n" for "$COPY/blib/arch/auto/Proc/Spawner/Spawner.xs.dll", ($UTF8 ? "$WIN/recorder-utf8.exe" : "$WIN/recorder.exe"), "$WIN/runner.exe", ($RUN ? "$COPY/run/Run.pm" : ()); close $e }
}

my %FIXTURE = ('a.txt' => "alpha\nbeta\n", 'b.txt' => "one two\n", 'file.txt' => "hello world\n", 'c.log' => "x\n",
  '.hidden' => "h\n", 'dir/x.txt' => "in dir\n", 'dir/sub/y.sh' => "echo y\n", 'home/.profile' => '', 'empty' => '');
my %done;
for my $f (glob "$OUT/run-*.jsonl") { open my $in, '<', $f or die; while (<$in>) { my $r = eval { decode_json($_) } or next; $done{$r->{id}} = 1 } }
my %acc; { open my $in, '<', $ST or die; my $h = <$in>; chomp $h; my @h = split /\t/, $h; my %c; @c{@h} = 0 .. $#h;
  while (<$in>) { chomp; my @f = split /\t/, $_, -1; $acc{$f[$c{id}]} = [$f[$c{verdict}], $f[$c{features}]] if $f[$c{large}] } }
my %only = map +($_ => 1), grep length, $ONLY =~ /^\@(.*)/s ? do { open my $in, '<', $1 or die; map { /^([^#\t\n][^\t\n]*)/ ? $1 : () } <$in> } : split /,/, $ONLY;
length $ONLY && !%only and die "-only: empty\n";
# A sample goes to worker (its index among the accepted samples) % J, done or not, as large-subset-runcompare.pl assigns
# them on a fresh run: a rerun then runs a sample as the same user in the same directory (names in outputs alike).
my %WK; if (length $WFROM) { for my $f (glob "$WFROM/run-*.jsonl") { my ($k) = $f =~ /run-(\d+)\.jsonl\z/ or next;
    $k < $J or die "-workers-from $WFROM: run-$k.jsonl, more workers than -j $J\n";
    open my $in, '<', $f or die; while (<$in>) { my $r = eval { decode_json($_) } or next; $WK{$r->{id}} = $k } }
  %WK or die "-workers-from $WFROM: no run-K.jsonl\n" }
my @todo; { open my $in, '<', $SJ or die; my $i = 0; while (<$in>) { my $s = decode_json($_); next unless $acc{$s->{id}};
    $s->{_k} = $WK{$s->{id}} // $i % $J; $i++; next if $done{$s->{id}} || %only && !$only{$s->{id}}; push @todo, $s; last if $MAX && @todo >= $MAX } }
my %wk = map +($_ => 1), length $WORKERS ? split(/,/, $WORKERS) : 0 .. $J - 1;
print STDERR scalar(@todo), " samples to run, ", scalar(keys %done), " done before\n";
my @kids;
for my $k (grep $wk{$_}, 0 .. $J - 1) {
  my $u = "$UP$k"; system("id $u >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -d /nonexistent $u") == 0 or die;
  my $pid = fork // die; if ($pid) { push @kids, $pid; next }
  worker($k, $u, [grep $_->{_k} == $k, @todo]); exit 0 }
waitpid $_, 0 for @kids;
print STDERR "finished\n";

sub wineenv { my ($u) = @_; (HOME => "$WB/home-$u", WINEPREFIX => "$WB/pfx-$u", WINEDEBUG => "-all", WINEDLLOVERRIDES => "winemenubuilder.exe=d;mscoree=d;mshtml=d", PATH => '/usr/bin:/bin', LANG => $LANGW, LC_ALL => $LANGW, USER => $u) }
sub asuser { my ($u, @cmd) = @_; my %e = wineenv($u);
  ('/usr/bin/prlimit', '--fsize=20000000', '--', '/usr/bin/setpriv', "--reuid=$u", "--regid=$u", '--clear-groups', '--inh-caps=-all', '--',
   '/usr/bin/env', '-i', map("$_=$e{$_}", sort keys %e), @cmd) }
sub worker {
  my ($k, $u, $list) = @_; my $W = "$BASE/w$k"; my $j = JSON::PP->new->utf8->canonical;
  my %we = wineenv($u);
  -e "$we{WINEPREFIX}/drive_c/windows/system32/msvcrt.dll" or die "no Wine prefix for $u: run mkprefix.sh $u first (outside unshare -n)\n";
  make_path("$BASE/req"); chmod 0755, "$BASE/req";
  if ($ENV_ON{tmp} || $ENV_ON{random}) {   # the worker's own mount namespace (see -env above)
    syscall(272, 0x00020000) == 0 or die "unshare(CLONE_NEWNS): $!\n";   # x86_64 Linux: SYS_unshare, CLONE_NEWNS
    my $mt = sub { system('mount', @_) == 0 or die "mount @_: failed\n" };
    $mt->('--make-rprivate', '/');
    if ($ENV_ON{tmp}) { $mt->('-t', 'tmpfs', '-o', 'mode=1777', 'none', $_) for qw(/tmp /var/tmp /dev/shm) }
    if ($ENV_ON{random}) { -e "$BASE/random" or die "$BASE/random: missing\n"; $mt->('--bind', "$BASE/random", $_) for qw(/dev/urandom /dev/random) } }
  my ($rout, $rin); my $rp = open2($rout, $rin, asuser($u, 'wine', zw("$BASE/runner.exe")));
  $SIG{PIPE} = sub { die "worker $k: the runner is gone (SIGPIPE)\n" };   # (died silently before, 2026-11-19)
  open my $out, '>>', "$OUT/run-$k.jsonl" or die; select((select($out), $| = 1)[0]);
  my %env = (PATH => zw("$BASE/quiet") . ';' . zw("$BASE/bin"), HOME => zw("$W/run/home"), LANG => 'C', LC_ALL => 'C', USER => $u, LOGNAME => $u,
    TERM => 'dumb', SHELL => '/bin/sh', RECLOG => zw("$W/log"), REALDIR => "$BASE/real", TMPDIR => zw("$W/run"),
    REALNAMES => join(' ', sort keys %REAL),
    # what Windows itself has in every process
    SystemRoot => 'C:\\windows', windir => 'C:\\windows', SystemDrive => 'C:', ComSpec => 'C:\\windows\\system32\\cmd.exe',
    PATHEXT => '.COM;.EXE;.BAT;.CMD', ProgramFiles => "C:\\Program Files", ProgramW6432 => "C:\\Program Files", "ProgramFiles(x86)" => "C:\\Program Files (x86)",
    CommonProgramFiles => "C:\\Program Files\\Common Files", LOCALAPPDATA => "C:\\users\\$u\\AppData\\Local", APPDATA => "C:\\users\\$u\\AppData\\Roaming",
    COMPUTERNAME => "RUNWIN", OS => "Windows_NT", PROCESSOR_ARCHITECTURE => "AMD64", NUMBER_OF_PROCESSORS => 4, TEMP => zw("$W/run"), TMP => zw("$W/run"), USERPROFILE => zw("$W/run/home"), USERNAME => $u,
    TRY_FILE => zw("$W/text"), ($RUN ? (PROC_SPAWNER_MISSING => 'posix_spawn fork', TRY_HIDE => 'PROC_SPAWNER_MISSING') : ()));
  delete @env{split /,/, $NOENV};
  @env{qw(WINREAL WINQUIET)} = (zw($WINREAL), 'kill') if length $WINREAL;
  for (@SETENV) { my ($n, $v) = /\A([^=]+)=(.*)\z/s or die "-setenv $_\n"; $env{$n} = $v }
  $env{TRY_HIDE} = join ' ', grep length, $env{TRY_HIDE} // '', split /,/, $HIDE if length $HIDE;
  my $cmd = join ' ', map(qq{"$_"}, $SP, '-I' . zw("$COPY/blib/lib"), '-I' . zw("$COPY/blib/arch"), ($RUN ? '-I' . zw("$COPY/run") : ()), zw("$COPY/t/try.pl"));
  {   # warm-up, not recorded: a Wine server's first start (a fresh /tmp, a restart) can take 20 s and more
    make_path("$W/run"); my $req = "$BASE/req/$k"; open my $o, '>:raw', $req or die;
    print $o join("\0", zw("$W/run"), 'NUL', zw("$W/out"), zw("$W/err"), 120000, 1000, qq{"$SP" -e 1}, map("$_=$env{$_}", sort keys %env), ''), "\0"; close $o; chmod 0644, $req;
    print $rin zw($req), "\n"; $rin->flush; my $ans = <$rout>; defined $ans or die "runner $k ended (warm-up)\n" }
  for my $s (@$list) {
    my %rec = (id => $s->{id}, src => $s->{src}, text => $s->{text}, verdict => $acc{$s->{id}}[0], features => $acc{$s->{id}}[1]);
    killrest($u);
    if ($ENV_ON{tmp}) {   # empty, but for Wine's server directory
      for my $d (qw(/tmp /var/tmp /dev/shm)) { opendir my $dh, $d or die; for my $n (grep !/^\.\.?\z/, readdir $dh) {
          next if $d eq '/tmp' && $n =~ /^wine-[A-Za-z0-9]{6}\z/ && (stat "$d/$n")[4] == getpwnam($u); remove_tree("$d/$n") } } }
    remove_tree($W); make_path("$W/run");
    for my $f (sort keys %FIXTURE) { my ($d) = $f =~ m{^(.*)/}; make_path("$W/run/$d") if $d; open my $o, '>', "$W/run/$f" or die; print $o $FIXTURE{$f}; close $o }
    { open my $o, '>:raw', "$W/text" or die; print $o Encode::encode_utf8($s->{text}); close $o }   # the bytes ours gets on Linux (in argv, a UTF-8 string)
    system('chown', '-R', "$u:$u", $W); chmod 0755, $W;
    { my @all = ("$W/run"); for (my $i = 0; $i < @all; $i++) { next if -l $all[$i] || !-d _; opendir my $dh, $all[$i] or die; push @all, map "$all[$i]/$_", grep !/^\.\.?\z/, readdir $dh }
      utime $MTIME, $MTIME, @all or die }
    for my $lf ("$W/log", "$W/out", "$W/err") { open my $l, '>', $lf or die; close $l; system('chown', "$u:$u", $lf) }
    utime $MTIME, $MTIME, $W;
    my $req = "$BASE/req/$k"; { open my $o, '>:raw', $req or die; print $o join "\0", zw("$W/run"), 'NUL', zw("$W/out"), zw("$W/err"), 5000, 5000, $cmd,
      map("$_=$env{$_}", sort keys %env), ''; print $o "\0"; close $o; chmod 0644, $req }
    my $t0 = Time::HiRes::time(); print $rin zw($req), "\n"; $rin->flush;
    my $ans = <$rout>; defined $ans or die "runner $k ended\n"; $ans =~ s/\r?\n\z//;
    my $wtime = sprintf "%.2f", Time::HiRes::time() - $t0;
    my ($st, $after) = $ans =~ /^(\d+) (\S+)\z/ or do { $rec{ours} = { error => $ans }; print $out $j->encode(\%rec), "\n"; next };
    killrest($u);
    my %r = (status => $st, out => slurp("$W/out"), err => slurp("$W/err"), rec => slurp("$W/log"), $after eq 'killed' ? (after => 'killed') : ());
    my (@files, @nomsg); my $walk; $walk = sub { no warnings "recursion"; my ($d, $p) = @_; opendir my $dh, $d or return;
      for my $n (sort grep !/^\.\.?\z/, readdir $dh) { my $f = "$d/$n";
        if (-l $f) { push @files, "$p$n -> " . readlink $f; push @nomsg, $files[-1] }
        elsif (-d $f) { push @files, "$p$n/"; push @nomsg, $files[-1]; $walk->($f, "$p$n/") }
        else { push @files, "$p$n " . (-s $f // '?') . ' ' . substr(Digest_sha($f), 0, 12); push @nomsg, "$p$n " . substr(Digest_sha_nomsg($f), 0, 12) } } };
    $walk->("$W/run", ''); $r{files} = join "\n", @files; $r{files_nomsg} = join "\n", @nomsg;
    $r{wtime} = $wtime; $rec{ours} = \%r;
    print $out $j->encode(\%rec), "\n" }
  close $rin; waitpid $rp, 0; close $out }

sub killrest {   # the Linux processes the bridge started and left (tail -f ...): every process of the user but Wine's own
  my ($u) = @_; my $uid = getpwnam $u;
  for my $p (glob '/proc/[0-9]*') { my @s = stat $p or next; $s[4] == $uid or next; my $exe = readlink("$p/exe") // next;
    next if $exe =~ m{/wine|wineserver|wine64|/prlimit\z|/setpriv\z|/env\z};   # Wine, and a runner still starting (prlimit, setpriv, env, then the wine script under sh)
    if (open my $c, "<", "$p/cmdline") { local $/; my $cl = <$c> // ""; next if $cl =~ m{/usr/bin/wine\0|runner\.exe} }
    kill 'KILL', $p =~ m{(\d+)\z} } }
sub slurp { my $f = shift; open my $i, '<:raw', $f or return ''; local $/; my $t = <$i> // ''; length $t > $LIMIT ? substr($t, 0, $LIMIT) . "\n[...cut]" : $t }
sub Digest_sha_nomsg { require Digest::SHA; open my $i, '<:raw', shift or return '?'; local $/; my $t = <$i> // '';
  $t =~ s/^(?:(?:\S*\/)?dash: \d+: |(?:\S*\/)?bash: (?:line \d+: )?|sh: ).*(?:\n|\z)//mg; Digest::SHA::sha256_hex($t) }
sub Digest_sha { require Digest::SHA; my $d = Digest::SHA->new(256); open my $i, '<:raw', shift or return '?'; $d->addfile($i); $d->hexdigest }
