#!/bin/bash
# mkprefix.sh USER: the Wine prefix of runwine.pl's worker USER (/runwin/pfx-USER), made outside any network namespace
u=$1; B=/runwin; id $u >/dev/null 2>&1 || useradd -M -s /usr/sbin/nologin -d /nonexistent $u
rm -rf $B/pfx-$u; mkdir -p $B/home-$u $B/pfx-$u; chown $u $B/home-$u $B/pfx-$u
E="env -i HOME=$B/home-$u WINEPREFIX=$B/pfx-$u WINEDEBUG=-all WINEDLLOVERRIDES=winemenubuilder.exe=d;mscoree=d;mshtml=d PATH=/usr/bin:/bin"
R="setpriv --reuid=$u --regid=$u --clear-groups --inh-caps=-all"
$R $E wine wineboot -i > /dev/null 2>&1; $R $E wineserver -w
$R $E wine reg add 'HKCU\Software\Wine\WineDbg' /v ShowCrashDialog /t REG_DWORD /d 0 /f > /dev/null 2>&1
$R $E wine reg delete 'HKLM\Software\Microsoft\Windows NT\CurrentVersion\AeDebug' /v Debugger /f > /dev/null 2>&1
$R $E wineserver -k; $R $E wineserver -w
test -e $B/pfx-$u/drive_c/windows/system32/msvcrt.dll && echo "$u: prefix ready" || echo "$u: FAILED"
