# Possible bugs of dash and bash seen in the runs

The collections hold, for every snippet, what dash 0.5.12 (`dash -c TEXT`) and bash 5.2.21 (`bash --posix -c TEXT`)
did with it.  Where the two differ, the difference is almost always intended: bash has features dash lacks, the
messages are worded differently, the exit statuses of the same error differ.  The cases below are those where one of
the shells contradicts POSIX, its own manual, or itself.  They come from the 1,195 rejected snippets on which dash and
bash differ ([`2026-11-26-post-0.13-rejected/`](2026-11-26-post-0.13-rejected/), every one read), and from the
distribution's records of single commands run by both shells (its `large-subset-threeway-differences.tsv` and
`large-subset-builtins-differences.tsv`, made from [`2026-11-22-post-0.13/`](2026-11-22-post-0.13/)).

Every command below was run again on 2026-11-27, with dash 0.5.12-6ubuntu5 and bash 5.2.21-2ubuntu4 (Ubuntu 24.04),
and gave what is shown.  The rules are cited from memory of POSIX.1-2017 (XCU) and of the shells' manuals, which
were not at hand; they need checking before a report is filed.  The last column is an estimate of the probability
that the behaviour is intended (a deliberate choice, or one the standard allows).

| # | Shell | What happens | Rule it seems to break | Snippets | Intended? |
|---|---|---|---|---|---|
| 1 | bash | In `bash --posix`, a fatal error in a `-c` string ends the shell with status **127** (plain bash too, for `${x?}`, `set -u` and the syntax error): an expansion error (`${x?}`, `set -u` with an unset variable, `$((4/0))`, a bad substitution) and a syntax error inside `$( )` (`echo a $(;) b`).  The same text from a file, from standard input or in a subshell gives 1 (2 for the syntax error).  dash gives 2 everywhere. | POSIX `sh`, EXIT STATUS: a non-interactive shell that detects an error returns 1 to 125; 127 is for a command file not found.  Also inconsistent with itself | 16 snippets, among them `NB:4769` (`echo $[4/0]`), `SC:Analytics.hs:prop_checkUnassignedReferences35` (`${arr[foo-bar]:?fail}`), `SC:Checks/Commands.hs:prop_checkExportedExpansions4` (`export ${foo?}`), `SC:Analytics.hs:prop_checkBadParameterSubstitution1` (`${foo$n}`) and 7 more bad substitutions | 15% |
| 2 | dash | A quote right after `${` or `${NAME` does not open a quoted string, so the quotes after it pair wrongly and the whole text fails to parse, also where that part never runs: `false && echo ${x"y"}; echo ok` and `if false; then echo ${'x'}; fi; echo ok` give "Syntax error: Unterminated quoted string", status 2.  bash prints `ok`. | XCU 2.3 and 2.6.2: quoted strings inside `${ }` are skipped when looking for the closing brace; an invalid expansion fails only when it is expanded | `SC:Analytics.hs:prop_checkBadParameterSubstitution6`, `…10` | 15% |
| 3 | bash | `$(( a[$i] ))` with `i` empty prints "a[]: bad array subscript" **twice**, then expands to 0 with status 0; `(( a[$i] ))` gives 1. | bash's manual: an arithmetic error makes the expansion fail; and one message per error | `SC:Analytics.hs:prop_checkArithmeticDeref6` | 25% |
| 4 | dash | `type` and `alias` do not discard a first `--`: `type -- ls` prints "--: not found" and ends with 127; `alias -- a=b` says "alias: -- not found", status 1 (the alias is set).  Its `command`, `umask`, `cd`, `read` and others do discard it. | XCU 1.4, Utility Description Defaults: utilities without options shall recognize `--` as a first argument to be discarded (`type` and `alias` are not special built-ins) | `NB:8077`, `SC:Checks/ShellSupport.hs:prop_checkBashisms124` | 25% |
| 5 | bash | An error inside a function defined in the `-c` string is labelled `environment: line 1:` instead of the shell's name (`$0`): `bash --posix -c 'f(){ nosuchcmd; }; f; nosuchcmd' myname` prints `environment: line 1: …` and then `myname: line 1: …`.  `${BASH_SOURCE[0]}` there is `environment`. | bash's manual, `-c`: `$0` is the name used in warning and error messages | `SC:Analytics.hs:prop_checkUnused16b` | 30% |
| 6 | dash | `cd nosuch/..` and `cd ../../.../..` succeed (status 0), though `nosuch` and `...` do not exist.  bash fails, status 1. | XCU `cd`, step 8.b.i: when the component before `..` is not a directory, `cd` writes an error and does nothing more | `SC:Analytics.hs:prop_checkUncheckedPopd13` (records of single commands) | 35% |
| 7 | dash | `.` with no operand does nothing and returns 0.  bash --posix: "filename argument required", status 2. | XCU `dot`: the operand is required; a usage error of a special built-in ends a non-interactive shell (XCU 2.8.1) | `TL:common/regex.md:10` | 40% |
| 8 | dash | `kill -l` lists `0` first among the signal names, but `kill -l 0` refuses it ("invalid signal number or exit status: 0", status 2). | XCU `kill -l`: lists the signal names; `0` is none.  Also inconsistent with itself | `TL:common/kill.md:13`, `TL:linux/kill.md:13` (records of single commands) | 40% |
| 9 | dash | `type nosuchcmd` writes "nosuchcmd: not found" to standard output (status 127); so does `command -V`.  bash writes it to standard error. | XCU `type`: diagnostics go to standard error (the form of the output is otherwise unspecified) | `NB:5652` | 60% |
| 10 | dash | `trap f BOGUS` prints "trap: BOGUS: bad trap" without the `dash: LINE:` prefix that its other messages have (status 1 and going on are right). | none; only inconsistent with itself | `SC:Checks/Commands.hs:prop_checkNonportableSignals4`, `SC:Checks/Commands.hs:prop_checkTrapQuotes3` | 70% |
| 11 | bash | `${a[-1]}` of an empty array prints "a: bad array subscript" and expands to nothing with status 0; the script goes on. | none (arrays are not POSIX); a message with success is inconsistent | `NB:4741` | 70% |
| 12 | dash | `[ ! -a file ]` and `[ ! -o x ]`: "unexpected operator", status 2.  `[ ! = x ]` follows the rule that a binary operator in the middle wins (status 1); bash applies it to `-a` and `-o` too (status 0). | XCU `test`, 3 arguments: if `$2` is a binary primary, the binary test of `$1` and `$3`.  `-a` and `-o` are binary primaries in POSIX.1-2017 (XSI, obsolescent), not in POSIX.1-2024 | `SC:Checks/ShellSupport.hs:prop_checkNegatedUnaryOps5`, `SC:Analytics.hs:prop_checkUnaryTestA2` (records of single commands) | 70% |
| 13 | dash | A message is written in three pieces (`dash: 1: `, the text, the newline: seen with `strace`), so the messages of two commands of a pipeline can mix: the run of `gcrane completion fish \| source` recorded `dash: 1: dash: 1: gcrane: not foundsource: not found` and two newlines. | none; output quality | `TL:linux/gcrane-completion.md:21`, `TL:linux/abbr.md:21` | 75% |
| 14 | dash | A file found on `PATH` that is not executable: "foo: Permission denied" with status 127; the same file named by its path gives 126.  bash gives 126 both ways. | XCU 2.9.1.1: the search looks for an executable file, so 127 is allowed; the message says otherwise | `PB:README.md:1630`, `…1636`, `…1672`, `…1682` | 75% |
| 15 | bash | `set -"$-"` (restoring the options) fails, because `$-` under `-c` holds `c`, which `set` refuses ("set: -c: invalid option"). dash's `$-` is empty there. | XCU 2.5.2, `-`: the current option flags; nothing promises that `set` takes them back | `SC:Checks/ShellSupport.hs:prop_checkBashisms89` | 80% |

Two more are recorded in the distribution's own documents, from its other runs:

- bash: in `bash --posix -c`, `shift 3` with fewer arguments and `export "1x=2"` print an error and the shell goes on,
  though bash's manual ("Bash POSIX Mode") says a non-interactive shell exits when a POSIX special built-in fails
  (the distribution's known issue X22).  Intended: 15%.
- dash: with `HOME` empty, `~` is dropped and `~/x` loses its prefix (`HOME=; set -- ~ ~/x; echo $# "$1"` gives
  `1 /x`), where POSIX treats the result of `~` as quoted and gives an empty field, as bash does
  (`large-subset-environment.md`, section 11).  Intended: 20%.

What was left out as intended: bash's own syntax and builtins (`[[`, `((`, arrays, `$'…'`, `<(…)`, `source`,
`shopt`, `declare`, `pushd`, …), which dash refuses or runs as programs that are not found; options of `read`,
`type`, `set -o` and others that only bash has; `$RANDOM` and the other variables only bash sets; brace expansion;
the different wording of messages and the different statuses of the same error (dash usually 2, bash 1); endless
loops that both shells run until they are stopped.
