# Possible bugs of dash 0.5.12

Eleven places where dash 0.5.12 (Ubuntu's 0.5.12-6ubuntu5, Ubuntu 24.04) seems to contradict POSIX, its own manual,
or itself.  The bash report is [`upstream-reports-bash.md`](upstream-reports-bash.md).

**Where they come from.**  The Perl module Proc::ShellSpawn, of the CPAN distribution Proc-Spawner
(<https://github.com/ilyaz-ai/Proc-Spawner>), runs shell text itself.  To test it, 41,952 snippets of shell text, taken
from public collections, were run in dash (`dash -c TEXT`), in bash 5.2.21 (`bash --posix -c TEXT`) and in the module,
each in a fresh directory, as an unprivileged user, for at most 5 seconds, and the results compared.  The runs are in
this repository, <https://github.com/ilyaz-ai/Proc-Spawner-results>.  Every place where dash and bash differed was read,
and the cases below are the ones a dialect difference does not explain.  A snippet's ID names its collection (`TL:` the
tldr pages, `NB:` NL2Bash, `SC:` ShellCheck's test cases, `PB:` the pure bash bible) and where in it the snippet is (a
file and line, an item's number, or a test's name); its text is in
the file `samples.jsonl` of the collections
[`proc-spawner/2026-11-22-post-0.13/`](https://github.com/ilyaz-ai/Proc-Spawner-results/tree/main/proc-spawner/2026-11-22-post-0.13)
and
[`proc-spawner/2026-11-26-post-0.13-rejected/`](https://github.com/ilyaz-ai/Proc-Spawner-results/tree/main/proc-spawner/2026-11-26-post-0.13-rejected).

**Checked.**  Each command below was run again on 2026-11-27, in an empty directory, and printed what is shown (`$`
starts a command; `[status N]` is the exit status of that whole command line).  The rules are quoted from the texts listed under "Sources".

**Intended?** is an estimate of the probability that the behaviour is deliberate, or allowed by the standard: a
judgement from the wording of the standard and of the manual, and from whether dash behaves the same way elsewhere.  It
is not a measurement.

How to use the table: copy a row's command as one line and run it in bash, in a new empty directory (rows 9 and 10 write
the files `t` and `p/foo` there; row 9 needs `strace`).  The column "dash prints" is what that command printed on
2026-11-27 (dash 0.5.12-6ubuntu5, bash 5.2.21-2ubuntu4, Ubuntu 24.04); the column "bash prints" is what the same
command printed with every `dash` replaced by `bash --posix` (bash in its POSIX mode; plain `bash` differs in rows 5
and 6).  The output columns show standard output and standard error together, one output line per line, as a terminal
shows them.  Each `echo $?` prints the exit status of the command just before it; `DIR` stands for the directory the
command ran in.  In the Markdown source of the table, `\|` stands for `|`.  The number of each row links to a section
with more detail and the rules quoted in full.

| # | Run this, in an empty directory | dash prints | bash prints | Why it looks wrong | Snippets | Intended? |
|---|---|---|---|---|---|---|
| [1](#1-a-quote-right-after--is-not-a-quote) | `dash -c 'false && echo ${x"y"}; echo ok'; echo $?` | <code>dash: 1: Syntax error: Unterminated quoted string</code><br><code>2</code> | <code>ok</code><br><code>0</code> | The `${…}` is never run, yet the whole script fails to parse. POSIX 2.3 rule 5, 2.6.2: quotes inside `${…}` are skipped over | `SC:Analytics.hs:prop_checkBadParameterSubstitution6`, `SC:Analytics.hs:prop_checkBadParameterSubstitution10` | 15% |
| [2](#2-with-home-empty--gives-no-field) | `dash -c 'HOME=; set -- ~; echo $#'; echo $?` | <code>0</code><br><code>0</code> | <code>1</code><br><code>0</code> | POSIX.1-2024 2.6.1: `~` with `HOME` empty gives one empty field | 88 in all, among them `NB:10096`, `NB:10108`, `NB:10109` | 20% |
| [3](#3-type-and-alias-do-not-discard---) | `dash -c 'type -- ls'; echo $?; dash -c 'alias -- a=b'; echo $?` | <code>--: not found</code><br><code>ls is /usr/bin/ls</code><br><code>127</code><br><code>alias: -- not found</code><br><code>1</code> | <code>ls is /usr/bin/ls</code><br><code>0</code><br><code>0</code> | POSIX 1.4: a utility that takes no options must discard a first `--`; `type` and `alias` take none | `NB:8077`, `SC:Checks/ShellSupport.hs:prop_checkBashisms124` | 20% |
| [4](#4-cd-nosuch-succeeds) | `cd /tmp; dash -c 'cd nosuch/.. && pwd'; echo $?` | <code>/tmp</code><br><code>0</code> | <code>bash: line 1: cd: nosuch/..: No such file or directory</code><br><code>1</code> | POSIX `cd` step 8.b.i: if `nosuch` is not a directory, an error and nothing more | `SC:Analytics.hs:prop_checkUncheckedPopd13` | 30% |
| [5](#5-kill--l-lists-0-and-kill--l-0-refuses-it) | `dash -c 'kill -l \| head -n 2 \| cut -c 1-20; kill -l 0'; echo $?` | <code>0</code><br><code>HUP</code><br><code>dash: 1: kill: invalid signal number or exit status: 0</code><br><code>2</code> | <code>HUP INT QUIT ILL TRA</code><br><code>EXIT</code><br><code>0</code> | `0` is not a signal name, and dash refuses to name it. POSIX `kill -l`; dash's manual | `TL:common/kill.md:13`, `TL:linux/kill.md:13` | 35% |
| [6](#6--without-an-operand-succeeds) | `dash -c '.; echo after'; echo $?` | <code>after</code><br><code>0</code> | <code>bash: line 1: .: filename argument required</code><br><code>.: usage: . filename [arguments]</code><br><code>2</code> | POSIX `dot`: the file operand is required; 2.8.1: a special built-in's error ends a non-interactive shell | `TL:common/regex.md:10` | 40% |
| [7](#7-traps-message-lacks-the-shells-prefix) | `dash -c 'trap f SIGKILL; local'; echo $?` | <code>trap: SIGKILL: bad trap</code><br><code>dash: 1: local: not in a function</code><br><code>2</code> | <code>bash: line 1: local: can only be used in a function</code><br><code>1</code> | Only `trap`'s message lacks the `dash: 1:` prefix | `SC:Checks/Commands.hs:prop_checkNonportableSignals4`, `SC:Checks/Commands.hs:prop_checkTrapQuotes3` | 70% |
| [8](#8----a-file--is-an-error) | `dash -c '[ ! -a file ]; echo $?; [ ! = x ]; echo $?'` | <code>dash: 1: [: -a: unexpected operator</code><br><code>2</code><br><code>1</code> | <code>0</code><br><code>1</code> | POSIX.1-2017 `test`, 3 arguments: a binary primary in the middle wins (`-a` is one there; POSIX.1-2024 removed it) | `SC:Checks/ShellSupport.hs:prop_checkNegatedUnaryOps5`, `SC:Analytics.hs:prop_checkUnaryTestA2` | 75% |
| [9](#9-a-message-is-written-in-three-pieces) | `strace -e trace=write -o t dash -c nosuchA 2>/dev/null; grep -c '^write(2' t` | <code>3</code> | <code>1</code> | One message, three writes (prefix, text, newline), so two commands of a pipeline that fail together can mix their messages; the section shows it. No rule; output quality | `TL:linux/gcrane-completion.md:21`, `TL:linux/abbr.md:21` | 75% |
| [10](#10-a-non-executable-file-on-path-permission-denied-with-status-127) | `mkdir -p p; echo 'echo hi' > p/foo; chmod 644 p/foo; dash -c 'PATH=$PWD/p; foo'; echo $?` | <code>dash: 1: foo: Permission denied</code><br><code>127</code> | <code>bash: line 1: DIR/p/foo: Permission denied</code><br><code>126</code> | 127 is right (XBD 8.3: PATH finds only executable files); the message is that of 126 | `PB:README.md:1630`, `PB:README.md:1636`, `PB:README.md:1672`, `PB:README.md:1682` | 80% |
| [11](#11-type-writes-not-found-to-standard-output) | `dash -c 'type nosuchcmd' 2>/dev/null; echo $?` | <code>nosuchcmd: not found</code><br><code>127</code> | <code>1</code> | Allowed: POSIX `type` leaves the output's form open, and dash's manual lists "not found" as a result | `NB:5652` | 90% |

## 1. A quote right after `${` is not a quote

```
$ dash -c 'false && echo ${x"y"}; echo ok'
dash: 1: Syntax error: Unterminated quoted string
[status 2]
$ dash -c "if false; then echo \${'x'}; fi; echo ok"
dash: 1: Syntax error: Unterminated quoted string
[status 2]
$ bash --posix -c 'false && echo ${x"y"}; echo ok'
ok
[status 0]
```

The first `"` (or `'`) after `${x` is not taken as opening a quoted string; the next one then opens a string that
runs to the end of the text.  So the whole text fails to parse, although the invalid expansion is never reached.

POSIX.1-2017, 2.3 Token Recognition, rule 5: "if instances of expansions or quoting are found nested within the
substitution, the shell shall recursively process them in the manner specified for the construct that is found."
2.6.2 Parameter Expansion: "The matching closing brace shall be determined by counting brace levels, skipping over
enclosed quoted strings, and command substitutions."

Snippets: `SC:Analytics.hs:prop_checkBadParameterSubstitution6` (`${"bar"}`),
`SC:Analytics.hs:prop_checkBadParameterSubstitution10` (`${'foo'}`).  Intended: 15%.

## 2. With `HOME` empty, `~` gives no field

```
$ dash -c 'HOME=; set -- ~; echo $#'
0
[status 0]
$ bash --posix -c 'HOME=; set -- ~; echo $#'
1
[status 0]
```

POSIX.1-2024, 2.6.1 Tilde Expansion: "If the word being expanded consists of only the <tilde> character and HOME is
set to the null string, this produces an empty field (as opposed to zero fields) as the expanded word."  POSIX.1-2017
says less, but points the same way: "The pathname resulting from tilde expansion shall be treated as if quoted to
prevent it being altered by field splitting and pathname expansion" (a quoted empty string is an empty field).

Snippets: 88, in example environments that set `HOME` empty (the record `large-subset-match.tsv` of Proc-Spawner lists
them), among them `NB:10096`, `NB:10108`, `NB:10109`.  Intended: 20%.

## 3. `type` and `alias` do not discard `--`

```
$ dash -c 'type -- ls; echo "st=$?"'
--: not found
ls is /usr/bin/ls
st=127
[status 0]
$ dash -c 'alias -- a=b; echo "st=$?"; alias a'
alias: -- not found
st=1
a='b'
[status 0]
$ dash -c 'command -V -- ls; echo "st=$?"'
ls is /usr/bin/ls
st=0
[status 0]
```

`type` takes `--` for a name to look up, and fails (127); `alias` complains about it but sets the alias.  dash's
`command`, `umask`, `cd` and `read` do discard a first `--`.

POSIX.1-2017, 1.4 Utility Description Defaults, OPTIONS: "Standard utilities that do not accept options, but that do
accept operands, shall recognize "--" as a first argument to be discarded."  The OPTIONS of `type` and of `alias`:
"None."  (2.14 lifts the rule only for some special built-ins; `type` and `alias` are not special built-ins.)

Snippets: `NB:8077` (`SCRIPT=$( readlink -m $( type -p $0 ))`), `SC:Checks/ShellSupport.hs:prop_checkBashisms124`
(`type -p test`).  Both pass `-p`, which `type` need not accept; trying them showed the `--` case.  Intended: 20%.

## 4. `cd nosuch/..` succeeds

```
$ dash -c 'cd /tmp && cd nosuch/.. && pwd'
/tmp
[status 0]
$ bash --posix -c 'cd /tmp && cd nosuch/.. && pwd'
bash: line 1: cd: nosuch/..: No such file or directory
[status 1]
```

(`/tmp` has no `nosuch`.)  POSIX.1-2017, `cd`, DESCRIPTION, step 8.b (the default, logical handling of `..`): "For each
dot-dot component, if there is a preceding component and it is neither root nor dot-dot, then: i. If the preceding
component does not refer (in the context of pathname resolution with symbolic links followed) to a directory, then the
cd utility shall display an appropriate error message and no further steps shall be taken."

Snippet: `SC:Analytics.hs:prop_checkUncheckedPopd13` (`cd ../../.../..`, where `...` does not exist).  Intended: 30%.

## 5. `kill -l` lists `0`, and `kill -l 0` refuses it

```
$ dash -c 'kill -l | head -3'
0
HUP
INT
[status 0]
$ dash -c 'kill -l 0'
dash: 1: kill: invalid signal number or exit status: 0
[status 2]
```

`0` is not a signal name, and dash itself refuses to name a signal 0.  POSIX.1-2017, `kill`, `-l`: "Write all values
of signal_name supported by the implementation, if no operand is given."  dash's manual: "List available signal names
without the SIG prefix (sigspecs).  If signum specified, display just the sigspec for that signal."

Snippets: `TL:common/kill.md:13`, `TL:linux/kill.md:13` (`kill -l`).  Intended: 35%.

## 6. `.` without an operand succeeds

```
$ dash -c '.; echo "after, st=$?"'
after, st=0
[status 0]
$ bash --posix -c '.; echo after'
bash: line 1: .: filename argument required
.: usage: . filename [arguments]
[status 2]
```

POSIX.1-2017, `dot`, SYNOPSIS: `. file` (the operand is required; a missing one is a usage error).  2.8.1
Consequences of Shell Errors, for a non-interactive shell: "Special built-in utility error: shall exit", with a
diagnostic message.

Snippet: `TL:common/regex.md:10` (`.`).  Intended: 40%.

## 7. `trap`'s message lacks the shell's prefix

```
$ dash -c 'trap f SIGKILL; echo "st=$?"; local'
trap: SIGKILL: bad trap
st=1
dash: 1: local: not in a function
[status 2]
```

The other messages start with the shell's name and the line number (`dash: 1:`); this one does not.  The status 1
and going on after it are right.  No rule; only inconsistent with the rest of dash.

Snippets: `SC:Checks/Commands.hs:prop_checkNonportableSignals4` (`trap f SIGKILL`),
`SC:Checks/Commands.hs:prop_checkTrapQuotes3`.  Intended: 70%.

## 8. `[ ! -a file ]` is an error

```
$ dash -c '[ ! -a file ]; echo "st=$?"; [ ! = x ]; echo "st=$?"'
dash: 1: [: -a: unexpected operator
st=2
st=1
[status 0]
$ bash --posix -c '[ ! -a file ]; echo "st=$?"'
st=0
[status 0]
```

POSIX.1-2017, `test`, 3 arguments: "If $2 is a binary primary, perform the binary test of $1 and $3."  dash does so for
`[ ! = x ]` (the strings `!` and `x` differ: 1), but not for `-a` (and `-o`), which are binary primaries there (XSI,
marked obsolescent); bash gives 0 (`!` and `file` are both non-empty).  POSIX.1-2024, `test`: "The -a and -o binary
primaries and the '(' and ')' operators have been removed", so by 2024 the result is unspecified.

Snippets: `SC:Checks/ShellSupport.hs:prop_checkNegatedUnaryOps5`, `SC:Analytics.hs:prop_checkUnaryTestA2`.
Intended: 75%.

## 9. A message is written in three pieces

```
$ strace -e trace=write -o trace.txt dash -c nosuchcmd1 2>/dev/null; grep '^write' trace.txt
write(2, "dash: 1: ", 9)                = 9
write(2, "nosuchcmd1: not found", 21)   = 21
write(2, "\n", 1)                       = 1
```

So when two commands of a pipeline fail at the same moment, their messages can mix.  The run of the snippet `gcrane
completion fish | source` recorded this standard error:

```
/usr/bin/dash: 1: /usr/bin/dash: 1: gcrane: not foundsource: not found
```

followed by two newlines.  It depends on timing, and is easy to see.  In 60 tries of

```
$ dash -c 'nosuchA | nosuchB'
```

the two messages came out mixed between 1 and 6 times (five series of 60), for example

```
dash: 1: dash: 1: nosuchA: not found
nosuchB: not found
```

(the message of `nosuchB` can also come first); the other times they came out as two whole lines.  No rule;
output quality.

Snippets: `TL:linux/gcrane-completion.md:21`, `TL:linux/abbr.md:21`.  Intended: 75%.

## 10. A non-executable file on `PATH`: "Permission denied" with status 127

```
$ mkdir p && printf 'echo hi\n' > p/foo && chmod 644 p/foo
$ dash -c 'PATH=$PWD/p; foo; echo "st=$?"; $PWD/p/foo; echo "st=$?"'
dash: 1: foo: Permission denied
st=127
dash: 1: DIR/p/foo: Permission denied
st=126
[status 0]
$ dash -c '""; echo "st=$?"'
dash: 1: : Permission denied
st=127
[status 0]
```

(`DIR` stands for the current directory.)  127 is right: XBD 8.3, PATH, is searched "until an executable file
with the specified name and appropriate execution permissions is found", and POSIX.1-2017 2.9.1.1: "If the search is
unsuccessful, the command shall fail with an exit status of 127".  But the message says "Permission denied", as for a
file found and not executable (126).  bash says 126 for the first two commands; for the empty command name `""` it
says ": command not found", status 127.

Snippets: `PB:README.md:1630` (`"$BASH"`, empty in dash), `PB:README.md:1636`, `PB:README.md:1672`,
`PB:README.md:1682`.  Intended: 80%.

## 11. `type` writes "not found" to standard output

```
$ dash -c 'type nosuchcmd 2>/dev/null; echo "st=$?"'
nosuchcmd: not found
st=127
[status 0]
```

bash writes it to standard error.  Allowed: POSIX.1-2017, `type`, STDOUT: "The standard output of type contains
information about each operand in an unspecified format."  dash's manual: "Possible resolutions are: shell keyword,
alias, shell builtin, command, tracked alias and not found."  Listed because a script that captures `$(type -p x)`
gets the text: `NB:5652` (`file $(readlink -f $(type -p rename))`).  Intended: 90%.

## Not listed

Differences that dash's dialect explains: bash's syntax and builtins (`[[`, `((`, arrays, `$'…'`, `<(…)`, `source`,
`shopt`, `declare`, `pushd`, …), which dash refuses or looks up as programs; options that only bash's builtins have;
variables only bash sets (`$RANDOM`, …); brace expansion; the wording of messages; the status of the same error (dash
usually 2, bash 1); endless loops.

## Sources

- POSIX.1-2017 (The Open Group Base Specifications Issue 7, 2018 edition), read on 2026-11-27 at
  <https://pubs.opengroup.org/onlinepubs/9699919799/>: XCU 1.4, 2.3, 2.6.1, 2.6.2, 2.8.1, 2.9.1.1, 2.14; XBD 8.3; the
  utilities `cd`, `kill`, `type`, `alias`, `test`, `dot` (from the Ubuntu package manpages-posix 2017a-2).
- POSIX.1-2024 (Issue 8), read the same day at <https://pubs.opengroup.org/onlinepubs/9799919799/>: XCU 2.6.1, `test`.
- dash's manual page, from the Ubuntu package dash 0.5.12-6ubuntu5.
