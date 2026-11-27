#!/bin/bash
# t5.sh: Git's xargs under Wine with PATH set inside Windows (cmd), so that it holds Git's usr\bin
# Result (2026-11-21, Wine 9.0, PortableGit 2.47.1): printenv and env echo x work; xargs echo x hangs (with or
# without input, echo by name or by path); find -exec echo x fails at once (Bad address): MSYS2's fork under Wine.
cd /runwin/dbg
t() { local s=$(/usr/bin/date +%s%N); /usr/bin/timeout 30 /usr/bin/wine cmd /c "$1" > /runwin/dbg/out 2> /runwin/dbg/err < /dev/null; local st=$?
  local e=$(( ($(/usr/bin/date +%s%N) - s) / 100000000 ))
  printf '%-90s status %s, %d.%d s, out %s, err %s\n' "$1" $st $((e/10)) $((e%10)) "$(/usr/bin/tr -d '\r' < /runwin/dbg/out | /usr/bin/tr '\n' '|' | /usr/bin/head -c 60)" "$(/usr/bin/grep -v -e FAST_CWD -e 'Cygwin WARNING' -e 'older Cygwin' -e 'available Cygwin' -e 'problems.html' -e '^.$' -e '^$' /runwin/dbg/err | /usr/bin/head -c 120 | /usr/bin/tr '\n' '|')"; }
t 'set PATH=Z:\runwin\pgit\usr\bin&& printenv PATH'
t 'set PATH=Z:\runwin\pgit\usr\bin&& env echo x'
t 'set PATH=Z:\runwin\pgit\usr\bin&& xargs echo x < NUL'
t 'set PATH=Z:\runwin\pgit\usr\bin&& xargs /usr/bin/echo x < NUL'
t 'set PATH=Z:\runwin\pgit\usr\bin&& echo a | xargs echo x'
t 'set PATH=Z:\runwin\pgit\usr\bin&& find . -maxdepth 0 -exec echo x ;'
