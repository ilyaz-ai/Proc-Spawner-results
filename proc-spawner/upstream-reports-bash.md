# Possible bugs of bash 5.2.21

Where bash seems to contradict POSIX, its own manual, or itself, found while comparing it with dash on shell
snippets taken from public collections (tldr pages, NL2Bash, ShellCheck's test cases, the pure bash and pure sh
bibles, the bash Cookbook).  bash ran as `bash --posix -c TEXT`, each snippet in a fresh directory, as an unprivileged user,
for at most 5 seconds.  The runs are in this repository:

- the 1,195 snippets that Proc-Spawner's parser rejects and on which dash and bash differ
  ([`2026-11-26-post-0.13-rejected/`](2026-11-26-post-0.13-rejected/), every one read);
- the runs of [`2026-11-22-post-0.13/`](2026-11-22-post-0.13/) and the records of the distribution Proc-Spawner made
  from them: `large-subset-match.tsv` (each snippet over all its environments), `large-subset-threeway-differences.tsv`
  and `large-subset-builtins-differences.tsv` (single commands run by both shells);
- probes run by the distribution (`doc/large-subset/dialect-cases/cases.txt`), where a row says so.

The snippet IDs name the collection a snippet comes from (`TL:` tldr, `NB:` NL2Bash, `SC:` ShellCheck's tests, `PB:`
the pure bash bible) and its place there; each collection's `samples.jsonl` has the text.  Every command in the table
was run again on 2026-11-27 (dash 0.5.12-6ubuntu5, bash 5.2.21-2ubuntu4, Ubuntu 24.04) and gave what is shown.  The
quoted rules are from the texts listed under "Sources".  The last column is an estimate of the probability that the
behaviour is intended (a deliberate choice, or one the standard allows).  The other shell's report:
[`upstream-reports-dash.md`](upstream-reports-dash.md).

| # | What happens | The rule, quoted | Snippets | Intended? |
|---|---|---|---|---|
| 1 | In `bash --posix`, a fatal error in a `-c` string ends the shell with status **127**: an expansion error (`${x?}`, `set -u` with an unset variable, `$((4/0))`, a bad substitution) or a syntax error inside `$( )` (`echo a $(;) b`).  Plain bash does the same for `${x?}`, `set -u` and the syntax error.  The same text from a file, from standard input or in a subshell gives 1 (2 for the syntax error); dash gives 2 everywhere. | POSIX 2.8.2: "If a command fails during word expansion or redirection, its exit status shall be between 1 and 125 inclusive."  `sh`, EXIT STATUS: "1-125 A non-interactive shell detected an error other than command_file not found or executable, including but not limited to syntax, redirection, or variable assignment errors"; "127 A specified command_file could not be found" | `NB:4769`, `SC:Analytics.hs:prop_checkUnassignedReferences35`, `SC:Checks/Commands.hs:prop_checkExportedExpansions4`, `SC:Checks/ShellSupport.hs:prop_checkBashisms93`, `SC:Checks/ShellSupport.hs:prop_checkMultiDimensionalArrays5`, `SC:Analytics.hs:prop_checkBadParameterSubstitution1`, `…4`, `…6`, `…7`, `…8`, `…10`, `…11`, `SC:Analytics.hs:prop_checkExpansionWithRedirection3`, `SC:Analytics.hs:prop_checkUnassignedReferences28`, `SC:Analytics.hs:prop_checkUnsupported5`, `…6` | 10% |
| 2 | In `bash --posix -c`, `shift 3; echo after` with fewer arguments and `n=1x; export "$n=2"; echo after` print an error and then `after`, status 0.  `set -o nosuch` and `unset -x` do end the shell (status 2).  dash ends the shell (status 2). | bash's manual, "Bash POSIX Mode", item 24: "If a POSIX special builtin returns an error status, a non-interactive shell exits."  POSIX 2.8.1: "Special built-in utility error: shall exit" (non-interactive shell) | probes `shiftover`, `exportbad` of the distribution's `doc/large-subset/dialect-cases/cases.txt`; in the corpus: `NB:9215` (`shift [n]`), `SC:Checks/Commands.hs:prop_checkExportedExpansions2` (`export "$foo"`), which end at the error | 15% |
| 3 | `$(( a[$i] ))` with `i` empty prints "a[]: bad array subscript" **twice**, then expands to 0 with status 0; `(( a[$i] ))` gives 1. | none in the manual; one error gives two messages, and an error is reported while the expansion succeeds | `SC:Analytics.hs:prop_checkArithmeticDeref6` | 25% |
| 4 | An error inside a function defined in the `-c` string is labelled `environment: line 1:` instead of the shell's name: `bash --posix -c 'f(){ nosuchcmd; }; f; nosuchcmd' myname` prints `environment: line 1: …`, then `myname: line 1: …`.  `${BASH_SOURCE[0]}` there is `environment`. | bash's manual, `-c`: "the first argument is assigned to $0 … The assignment to $0 sets the name of the shell, which is used in warning and error messages." | `SC:Analytics.hs:prop_checkUnused16b` | 30% |
| 5 | `${a[-1]}` of an empty array prints "a: bad array subscript" and expands to nothing with status 0; the script goes on. | none (arrays are not POSIX; the manual describes negative subscripts but not this case); a message with success is inconsistent | `NB:4741` (`cd "${dirs[-1]}"`) | 70% |
| 6 | `set -"$-"` (restoring the options) fails, because `$-` under `-c` holds `c`, which `set` refuses ("set: -c: invalid option").  dash's `$-` is empty there. | POSIX 2.5.2, `-`: "Expands to the current option flags … as specified on invocation, by the set special built-in command, or implicitly by the shell."  bash's manual says the same; nothing promises that `set` takes them back | `SC:Checks/ShellSupport.hs:prop_checkBashisms89` | 85% |

What was left out as intended: bash's own syntax and builtins (`[[`, `((`, arrays, `$'…'`, `<(…)`, `source`,
`shopt`, `declare`, `pushd`, …), which dash refuses or runs as programs that are not found; options of `read`,
`type`, `set -o` and others that only bash has; `$RANDOM` and the other variables only bash sets; brace expansion;
the different wording of messages and the different statuses of the same error (dash usually 2, bash 1); endless
loops that both shells run until they are stopped.

## Sources

- POSIX.1-2017 (The Open Group Base Specifications Issue 7, 2018 edition), read on 2026-11-27 at
  <https://pubs.opengroup.org/onlinepubs/9699919799/>: XCU chapter 1 (1.4), chapter 2 (2.3, 2.5.2, 2.6.1, 2.6.2, 2.8.1,
  2.8.2, 2.9.1.1, 2.14), XBD chapter 8 (8.3); the utilities `sh`, `cd`, `kill`, `type`, `alias`, `test`, `dot` from
  the Ubuntu package manpages-posix 2017a-2.
- POSIX.1-2024 (Issue 8), read the same day at <https://pubs.opengroup.org/onlinepubs/9799919799/>: XCU chapter 2
  (2.6.1, 2.8.2), the utilities `sh`, `test`, `kill`.
- bash's manual page and info manual ("Bash POSIX Mode"), from the Ubuntu package bash 5.2.21-2ubuntu4; dash's manual
  page, from dash 0.5.12-6ubuntu5.
