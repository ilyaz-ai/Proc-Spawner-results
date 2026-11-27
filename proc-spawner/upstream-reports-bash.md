# Possible bugs of bash 5.2.21

Six places where bash 5.2.21 (Ubuntu's 5.2.21-2ubuntu4, Ubuntu 24.04) seems to contradict POSIX, its own manual, or
itself.  The dash report is [`upstream-reports-dash.md`](upstream-reports-dash.md).

**Where they come from.**  The Perl module Proc::ShellSpawn, of the CPAN distribution Proc-Spawner
(<https://github.com/ilyaz-ai/Proc-Spawner>), runs shell text itself.  To test it, 41,952 snippets of shell text, taken
from public collections, were run in bash in its POSIX mode (`bash --posix -c TEXT`), in dash 0.5.12 (`dash -c TEXT`)
and in the module, each in a fresh directory, as an unprivileged user, for at most 5 seconds, and the results compared.
The runs are in this repository, <https://github.com/ilyaz-ai/Proc-Spawner-results>.  Every place where bash and dash
differed was read, and the cases below are the ones a dialect difference does not explain.  A snippet's ID names its
collection (`NB:` NL2Bash, `SC:` ShellCheck's test cases) and where in it the snippet is (an item's number or a
test's name); its text is in the file `samples.jsonl`
of the collections
[`proc-spawner/2026-11-22-post-0.13/`](https://github.com/ilyaz-ai/Proc-Spawner-results/tree/main/proc-spawner/2026-11-22-post-0.13)
and
[`proc-spawner/2026-11-26-post-0.13-rejected/`](https://github.com/ilyaz-ai/Proc-Spawner-results/tree/main/proc-spawner/2026-11-26-post-0.13-rejected).

**Checked.**  Each command below was run again on 2026-11-27, in an empty directory, and printed what is shown (`$`
starts a command; `[status N]` is the exit status of that whole command line).  All use `bash --posix`, except where `bash` alone is shown.  The
rules are quoted from the texts listed under "Sources".

**Intended?** is an estimate of the probability that the behaviour is deliberate, or allowed by the standard: a
judgement from the wording of the standard and of the manual, and from whether bash behaves the same way elsewhere.  It
is not a measurement.

How to use the table: copy a row's command as one line and run it in bash, in a new empty directory (row 1 writes the file
`s.sh` there).  The column "bash prints" is what that command printed on 2026-11-27 (bash 5.2.21-2ubuntu4, dash
0.5.12-6ubuntu5, Ubuntu 24.04); the column "dash prints" is what the same command printed with every `bash --posix`
replaced by `dash`.  The output columns show standard output and standard error together, one output line per line, as a terminal
shows them.  Each `echo $?` prints the exit status of the command just before it.  The number of each row
links to a section with more detail and the rules quoted in full.

| # | Run this, in an empty directory | bash prints | dash prints | Why it looks wrong | Snippets | Intended? |
|---|---|---|---|---|---|---|
| [1](#1-a-fatal-error-in--c-ends-the-shell-with-status-127) | `bash --posix -c 'echo ${x?}; echo after'; echo $?; echo 'echo ${x?}; echo after' > s.sh; bash --posix s.sh; echo $?` | <code>bash: line 1: x: parameter not set</code><br><code>127</code><br><code>s.sh: line 1: x: parameter not set</code><br><code>1</code> | <code>dash: 1: x: parameter not set</code><br><code>2</code><br><code>s.sh: 1: x: parameter not set</code><br><code>2</code> | POSIX 2.8.2: a command that fails in expansion has status 1 to 125; 127 means "not found". The same text in a file gives 1 | 16 in all, among them `NB:4769`, `SC:Analytics.hs:prop_checkUnassignedReferences35`, `SC:Checks/Commands.hs:prop_checkExportedExpansions4` | 10% |
| [2](#2-a-special-builtins-error-does-not-end-the-shell) | `bash --posix -c 'shift 3; echo after'; echo $?` | <code>bash: line 1: shift: 3: shift count out of range</code><br><code>after</code><br><code>0</code> | <code>dash: 1: shift: can't shift that many</code><br><code>2</code> | bash's manual, POSIX mode item 24, and POSIX 2.8.1: a special builtin's error ends a non-interactive shell | probes `shiftover`, `exportbad`; `NB:9215`, `SC:Checks/Commands.hs:prop_checkExportedExpansions2` | 15% |
| [3](#3--ai--with-i-empty-two-messages-and-success) | `bash --posix -c 'i=; echo $(( a[$i] ))'; echo $?` | <code>bash: line 1: a[]: bad array subscript</code><br><code>bash: line 1: a[]: bad array subscript</code><br><code>0</code><br><code>0</code> | <code>dash: 1: arithmetic expression: expecting EOF: " a[] "</code><br><code>2</code> | One error, two messages, and the expansion succeeds | `SC:Analytics.hs:prop_checkArithmeticDeref6` | 25% |
| [4](#4-errors-in-a-function-are-labelled-environment) | `bash --posix -c 'f(){ nosuchcmd; }; f; nosuchcmd' myname; echo $?` | <code>environment: line 1: nosuchcmd: command not found</code><br><code>myname: line 1: nosuchcmd: command not found</code><br><code>127</code> | <code>myname: 1: nosuchcmd: not found</code><br><code>myname: 1: nosuchcmd: not found</code><br><code>127</code> | bash's manual, `-c`: `$0` (here `myname`) is the name used in error messages | `SC:Analytics.hs:prop_checkUnused16b` | 30% |
| [5](#5-a-1-of-an-empty-array-a-message-and-success) | `bash --posix -c 'a=(); echo "[${a[-1]}]"'; echo $?` | <code>bash: line 1: a: bad array subscript</code><br><code>[]</code><br><code>0</code> | <code>dash: 1: Syntax error: "(" unexpected</code><br><code>2</code> | An error message, yet the expansion and the command succeed | `NB:4741` | 70% |
| [6](#6-set----cannot-restore-the-options) | `bash --posix -c 'set -"$-"; echo after'; echo $?` | <code>bash: line 1: set: -c: invalid option</code><br><code>set: usage: set [-abefhkmnptuvxBCEHPT] [-o option-name] [--] [-] [arg ...]</code><br><code>2</code> | <code>after</code><br><code>0</code> | Allowed by POSIX 2.5.2, but the common way of saving and restoring the options, `set -"$-"`, fails and ends the shell | `SC:Checks/ShellSupport.hs:prop_checkBashisms89` | 85% |

## 1. A fatal error in `-c` ends the shell with status 127

```
$ bash --posix -c 'echo ${x?}; echo after'
bash: line 1: x: parameter not set
[status 127]
$ bash --posix -c 'set -u; echo $y; echo after'
bash: line 1: y: unbound variable
[status 127]
$ bash --posix -c 'echo $((4/0)); echo after'
bash: line 1: 4/0: division by 0 (error token is "0")
[status 127]
$ bash --posix -c 'echo ${foo$n}; echo after'
bash: line 1: ${foo$n}: bad substitution
[status 127]
$ bash --posix -c 'echo a $(;) b; echo after'
bash: -c: line 1: syntax error near unexpected token `;'
bash: -c: line 1: `echo a $(;) b; echo after'
[status 127]
```

The same error elsewhere gives 1:

```
$ printf 'echo ${x?}; echo after\n' > s.sh
$ bash --posix s.sh
s.sh: line 1: x: parameter not set
[status 1]
$ bash --posix -s < s.sh
bash: line 1: x: parameter not set
[status 1]
$ bash --posix -c '(echo ${x?}); echo "subshell: $?"'
bash: line 1: x: parameter not set
subshell: 1
[status 0]
```

Without `--posix`, `bash -c 'echo ${x?}'` also ends with 127; `bash -c 'echo $((4/0)); echo after'` ends with 1.
dash ends with 2 in every case above (the same commands with `dash` in place of `bash --posix`).  127 is the status of a command that is not found; here every command was
found.

POSIX.1-2017, 2.8.2 Exit Status for Commands: "If a command fails during word expansion or redirection, its exit
status shall be between 1 and 125 inclusive."  `sh`, EXIT STATUS: "1-125 A non-interactive shell detected an error
other than command_file not found or executable, including but not limited to syntax, redirection, or variable
assignment errors"; "127 A specified command_file could not be found by a non-interactive shell."

Snippets (16, each ending with 127 in bash): `NB:4769` (`echo $[4/0] || exit $?`),
`SC:Analytics.hs:prop_checkUnassignedReferences35` (`echo ${arr[foo-bar]:?fail}`),
`SC:Checks/Commands.hs:prop_checkExportedExpansions4` (`export ${foo?}`), `SC:Checks/ShellSupport.hs:prop_checkBashisms93`,
`SC:Checks/ShellSupport.hs:prop_checkMultiDimensionalArrays5`, and the bad substitutions
`SC:Analytics.hs:prop_checkBadParameterSubstitution1`, `SC:Analytics.hs:prop_checkBadParameterSubstitution4`,
`SC:Analytics.hs:prop_checkBadParameterSubstitution6`, `SC:Analytics.hs:prop_checkBadParameterSubstitution7`,
`SC:Analytics.hs:prop_checkBadParameterSubstitution8`, `SC:Analytics.hs:prop_checkBadParameterSubstitution10`,
`SC:Analytics.hs:prop_checkBadParameterSubstitution11`,
`SC:Analytics.hs:prop_checkExpansionWithRedirection3`, `SC:Analytics.hs:prop_checkUnassignedReferences28`,
`SC:Analytics.hs:prop_checkUnsupported5`, `SC:Analytics.hs:prop_checkUnsupported6`.  Intended: 10%.

## 2. A special builtin's error does not end the shell

```
$ bash --posix -c 'shift 3; echo after'
bash: line 1: shift: 3: shift count out of range
after
[status 0]
$ bash --posix -c 'n=1x; export "$n=2"; echo after'
bash: line 1: export: `1x=2': not a valid identifier
after
[status 0]
$ bash --posix -c 'set -o nosuch; echo after'
bash: line 1: set: nosuch: invalid option name
[status 2]
```

`shift` and `export` are special builtins, as `set` is; the error of `set` ends the shell, the errors of `shift` and
`export` do not.  dash ends the
shell in all three.

bash's manual, "Bash POSIX Mode", item 24: "If a POSIX special builtin returns an error status, a non-interactive
shell exits."  POSIX.1-2017, 2.8.1 Consequences of Shell Errors, for a non-interactive shell: "Special built-in utility
error: shall exit."

Seen in the probes `shiftover` and `exportbad` of Proc-Spawner's `doc/large-subset/dialect-cases/cases.txt` (the two
commands above).  The corpus snippets with such an error end at it, so they show the message but not whether the
shell goes on: `NB:9215` (`shift [n]`), `SC:Checks/Commands.hs:prop_checkExportedExpansions2` (`export "$foo"`).
Intended: 15%.

## 3. `$(( a[$i] ))` with `i` empty: two messages, and success

```
$ bash --posix -c 'i=; echo $(( a[$i] )); echo "st=$?"'
bash: line 1: a[]: bad array subscript
bash: line 1: a[]: bad array subscript
0
st=0
[status 0]
$ bash --posix -c 'i=; (( a[$i] )); echo "st=$?"'
bash: line 1: a[]: bad array subscript
bash: line 1: a[]: bad array subscript
st=1
[status 0]
```

One error gives two messages, and the expansion that reports it succeeds (0), where other arithmetic errors, such as
`$((4/0))` in item 1, end the shell.  No rule in the manual; inconsistent with the rest of bash.

Snippet: `SC:Analytics.hs:prop_checkArithmeticDeref6` (`(( a[$i] ))`).  Intended: 25%.

## 4. Errors in a function are labelled `environment`

```
$ bash --posix -c 'f(){ nosuchcmd; }; f; nosuchcmd' myname
environment: line 1: nosuchcmd: command not found
myname: line 1: nosuchcmd: command not found
[status 127]
$ bash --posix -c 'f(){ echo "${BASH_SOURCE[0]}"; }; f' myname
environment
[status 0]
```

The same error is labelled `myname` outside the function and `environment` inside it (the name bash uses for functions
imported from the environment).  bash's manual, `-c`: "If there are arguments after the command_string, the first
argument is assigned to $0 … The assignment to $0 sets the name of the shell, which is used in warning and error
messages."

Snippet: `SC:Analytics.hs:prop_checkUnused16b` (`f() { local -x foo; foo=42; bar; }; f`).  Intended: 30%.

## 5. `${a[-1]}` of an empty array: a message, and success

```
$ bash --posix -c 'a=(); echo "[${a[-1]}]"; echo "st=$?"'
bash: line 1: a: bad array subscript
[]
st=0
[status 0]
```

An error is reported, and the expansion and the command succeed.  Arrays are not POSIX; the manual describes negative
subscripts ("an index of -1 references the last element") but not this case.

Snippet: `NB:4741` (`cd "${dirs[-1]}"`).  Intended: 70%.

## 6. `set -"$-"` cannot restore the options

```
$ bash --posix -c 'echo "[$-]"; set -"$-"; echo "st=$?"'
[hBc]
bash: line 1: set: -c: invalid option
set: usage: set [-abefhkmnptuvxBCEHPT] [-o option-name] [--] [-] [arg ...]
[status 2]
```

Under `-c`, `$-` holds `c`, which `set` refuses; since `set` is a special builtin, the shell ends.  So a script that
saves `$-` and restores it with `set` fails under `bash -c`.  (dash's `$-` is empty there: `dash -c 'echo "[$-]"'`
prints `[]`.)  Allowed: POSIX.1-2017, 2.5.2, `-`: "Expands to the current option flags (the single-letter option names
concatenated into a string) as specified on invocation, by the set special built-in command, or implicitly by the
shell"; bash's manual says the same, and neither promises that `set` takes them back.

Snippet: `SC:Checks/ShellSupport.hs:prop_checkBashisms89` (`opts=$-; set -"$opts"`).  Intended: 85%.

## Not listed

Differences that bash's own features explain: its syntax and builtins that dash lacks, options that only its builtins
have, variables only it sets, brace expansion; the wording of messages; the status of the same error where both are
between 1 and 125 (dash usually 2, bash 1); endless loops.

## Sources

- POSIX.1-2017 (The Open Group Base Specifications Issue 7, 2018 edition), read on 2026-11-27 at
  <https://pubs.opengroup.org/onlinepubs/9699919799/>: XCU 2.5.2, 2.8.1, 2.8.2; the utility `sh` (from the Ubuntu
  package manpages-posix 2017a-2).
- bash's manual page and info manual ("Bash POSIX Mode"), from the Ubuntu package bash 5.2.21-2ubuntu4.
