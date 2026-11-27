#!/bin/bash
# bridge.sh REQDIR: run a Linux program for recorder.exe (Windows, under Wine), all through files in REQDIR:
# argv (NUL-separated: name, args), env (NUL-separated NAME=VALUE, the Windows process's), cwd, in (the input) or
# noin (none) or neither (the run's own: BASE/wK/stdin, else /dev/null).  Writes out, err, then done (the status).
d=$1; W=${d%/*}
mapfile -d '' -t A < "$d/argv"; mapfile -d '' -t E < "$d/env"
n=${A[0]}; unset 'A[0]'
U=()
for kv in "${E[@]}"; do k=${kv%%=*}; v=${kv#*=}
  case $k in PATH|Path|path) continue;; esac
  D='@DROP@'; [ -n "$D" ] && [[ $k =~ ^($D)$ ]] && continue   # runwine.pl -bridge-drop: names the Linux program does not get
  case $k in RECLOG|HOME|TMPDIR|TEMP|TMP|USERPROFILE|REALDIR) case $v in [Zz]:*) v=${v#??}; v=${v//\\//};; esac;; esac
  U+=("$k=$v"); done
LP='@LPATH@'
# runwine.pl -bridge-env-path: env or printenv only listing the environment (no command to run) gets the snippet's own
# PATH, written as MSYS programs on Windows show it (Z: dropped, \ as /, ; as :); otherwise the bridge's own
listing=; if [ -n '@ENVPATH@' ]; then case $n in printenv) listing=1;; env) listing=1; for x in "${A[@]}"; do case $x in -*|*=*) ;; *) listing=;; esac; done;; esac; fi
if [ -n "$listing" ]; then
  for kv in "${E[@]}"; do case $kv in PATH=*|Path=*|path=*) v=${kv#*=}; v=${v//[Zz]:/}; v=${v//\\//}; LP=${v//;/:};; esac; done
fi
U+=("PATH=$LP")
cd "$(cat "$d/cwd")" 2>/dev/null || cd "$W"
if [ -e "$d/in" ]; then exec 0< "$d/in"; elif [ -e "$d/noin" ]; then exec 0<&-; elif [ -e "$W/stdin" ]; then exec 0< "$W/stdin"; else exec 0< /dev/null; fi
env -i "${U[@]}" "@REALDIR@/$n" "${A[@]}" > "$d/out" 2> "$d/err"
echo $? > "$d/done.t"; mv "$d/done.t" "$d/done"
