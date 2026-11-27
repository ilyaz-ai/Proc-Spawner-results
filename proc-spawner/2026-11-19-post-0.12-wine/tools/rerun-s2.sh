#!/bin/bash
# rerun-s2.sh (2026-11-21): the snippets of row (s2) again, both ways: without USERNAME, TMP, PATHEXT (the modules default it),
# PATH written with / (the module looks it up on the shell's drive); of the Windows variables only SystemRoot, and
# ProgramFiles and ProgramW6432 (without them X77 warns at every start); the
# bridge passes the Linux program neither Wine's own variables (WINE*: Wine adds them to every process) nor SystemRoot and SystemDrive (Wine adds both),
# and env or printenv listing the environment the snippet's PATH as MSYS shows it.
# Otherwise as pipeline9.sh ran them (-env tmp,random,mtime, the base run's workers).  OUT: the output directory.
cd /work/ps; T=doc/large-subset/tools; S="corpus-work/samples.jsonl corpus-work/samples.tsv"; O=${OUT:-/work/res/s2}; mkdir -p $O; cp -n /work/res/s2/s2.ids $O/ 2>/dev/null
B=/home/user/proc-spawner/corpus-work
win() { unshare -n perl /work/win/runwine.pl -j 4 -env tmp,random,mtime -noenv 'USERNAME,TMP,TEMP,PATHEXT,COMPUTERNAME,OS,PROCESSOR_ARCHITECTURE,NUMBER_OF_PROCESSORS,APPDATA,LOCALAPPDATA,CommonProgramFiles,ProgramFiles(x86),USERPROFILE,windir,SystemDrive,ComSpec' -setenv "PATH=/runcompare/quiet;/runcompare/bin" -bridge-drop 'WINE.*|SystemRoot|SystemDrive' -bridge-env-path -user rc -base /runcompare -dist /work/psw -tools $T "$@"; }
for u in rc0 rc1 rc2 rc3; do find /tmp /var/tmp /dev/shm -xdev -mindepth 1 -maxdepth 1 -user $u -exec rm -rf {} + 2>/dev/null; done
win -workers-from $B/run -only @$O/s2.ids $S $O/win-posix_spawn > $O/win-posix_spawn.log 2>&1
win -run -runpm /work/run/Run.pm -workers-from $B/run-system1 -only @$O/s2.ids $S $O/win-system1 > $O/win-system1.log 2>&1
echo "s2 END" >> $O/done.txt
