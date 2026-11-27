# Possible bugs of dash 0.5.12

Where dash seems to contradict POSIX, its own manual, or itself, found while comparing it with bash on shell
snippets taken from public collections (tldr pages, NL2Bash, ShellCheck's test cases, the pure bash and pure sh
bibles, the bash Cookbook).  dash ran as `dash -c TEXT`, each snippet in a fresh directory, as an unprivileged user,
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
[`upstream-reports-bash.md`](upstream-reports-bash.md).

| # | What happens | The rule, quoted | Snippets | Intended? |
|---|---|---|---|---|
| 1 | A quote right after `${` or `${NAME` does not open a quoted string, so the quotes after it pair wrongly and the whole text fails to parse, also where that part never runs: `false && echo ${x"y"}; echo ok` and `if false; then echo ${'x'}; fi; echo ok` give "Syntax error: Unterminated quoted string", status 2.  bash prints `ok`. | POSIX 2.3, rule 5: "if instances of expansions or quoting are found nested within the substitution, the shell shall recursively process them in the manner specified for the construct that is found."  2.6.2: "The matching closing brace shall be determined by counting brace levels, skipping over enclosed quoted strings, and command substitutions." | `SC:Analytics.hs:prop_checkBadParameterSubstitution6` (`${"bar"}`), `…10` (`${'foo'}`) | 15% |
| 2 | With `HOME` empty, `~` alone gives no field at all: `HOME=; set -- ~; echo $#` prints 0.  bash prints 1 (one empty field). | POSIX.1-2017, 2.6.1: "The pathname resulting from tilde expansion shall be treated as if quoted to prevent it being altered by field splitting and pathname expansion."  POSIX.1-2024, 2.6.1: "If the word being expanded consists of only the <tilde> character and HOME is set to the null string, this produces an empty field (as opposed to zero fields) as the expanded word." | 88 snippets in their example environments with `HOME` empty (the ruling of `large-subset-match.tsv` that names this bug), among them `NB:10096`, `NB:10108`, `NB:10109` | 20% |
| 3 | `type` and `alias` do not discard a first `--`: `type -- ls` prints "--: not found" and ends with 127; `alias -- a=b` says "alias: -- not found", status 1 (the alias is set).  Its `command`, `umask`, `cd`, `read` and others do discard it. | POSIX 1.4, Utility Description Defaults, OPTIONS: "Standard utilities that do not accept options, but that do accept operands, shall recognize "--" as a first argument to be discarded."  `type` and `alias`, OPTIONS: "None." (Both are regular built-ins; 2.14 lifts the rule only for special built-ins) | `NB:8077` (`type -p $0`), `SC:Checks/ShellSupport.hs:prop_checkBashisms124` (`type -p test`) | 20% |
| 4 | `cd nosuch/..` and `cd ../../.../..` succeed (status 0), though `nosuch` and `...` do not exist.  bash fails, status 1. | POSIX `cd`, step 8.b.i: "If the preceding component does not refer (in the context of pathname resolution with symbolic links followed) to a directory, then the cd utility shall display an appropriate error message and no further steps shall be taken." | `SC:Analytics.hs:prop_checkUncheckedPopd13` (`cd ../../.../..`) | 30% |
| 5 | `kill -l` lists `0` first among the signal names, but `kill -l 0` refuses it ("invalid signal number or exit status: 0", status 2). | POSIX `kill`, `-l`: "Write all values of signal_name supported by the implementation".  dash's manual: "List available signal names without the SIG prefix (sigspecs).  If signum specified, display just the sigspec for that signal." | `TL:common/kill.md:13`, `TL:linux/kill.md:13` | 35% |
| 6 | `.` with no operand does nothing and returns 0.  bash --posix: "filename argument required", status 2. | POSIX `dot`, SYNOPSIS: "`. file`" (the operand is required); 2.8.1: "Special built-in utility error: shall exit" | `TL:common/regex.md:10` | 40% |
| 7 | `trap f SIGKILL` prints "trap: SIGKILL: bad trap" without the `dash: LINE:` prefix that its other messages have (status 1 and going on are right). | none; only inconsistent with itself | `SC:Checks/Commands.hs:prop_checkNonportableSignals4`, `SC:Checks/Commands.hs:prop_checkTrapQuotes3` | 70% |
| 8 | `[ ! -a file ]` and `[ ! -o x ]`: "unexpected operator", status 2.  `[ ! = x ]` follows the rule (status 1); bash applies it to `-a` and `-o` too (status 0). | POSIX.1-2017 `test`, 3 arguments: "If $2 is a binary primary, perform the binary test of $1 and $3."  `-a` and `-o` are binary primaries there (XSI, marked obsolescent); POSIX.1-2024: "The -a and -o binary primaries and the '(' and ')' operators have been removed." | `SC:Checks/ShellSupport.hs:prop_checkNegatedUnaryOps5`, `SC:Analytics.hs:prop_checkUnaryTestA2` | 75% |
| 9 | A message is written in three pieces (`dash: 1: `, the text, the newline: seen with `strace`), so the messages of two commands of a pipeline can mix: the run of `gcrane completion fish \| source` recorded `dash: 1: dash: 1: gcrane: not foundsource: not found` and two newlines. | none; output quality | `TL:linux/gcrane-completion.md:21`, `TL:linux/abbr.md:21` | 75% |
| 10 | A file found on `PATH` that is not executable: "foo: Permission denied" with status 127; the same file named by its path gives 126.  bash gives 126 both ways.  (In the snippets, an empty command name: `""` gives ": Permission denied", 127.) | XBD 8.3, PATH: searched "until an executable file with the specified name and appropriate execution permissions is found"; POSIX 2.9.1.1: "If the search is unsuccessful, the command shall fail with an exit status of 127".  So 127 is right; the message says otherwise | `PB:README.md:1630` (`"$BASH"`), `PB:README.md:1636`, `PB:README.md:1672`, `PB:README.md:1682` | 80% |
| 11 | `type nosuchcmd` writes "nosuchcmd: not found" to standard output (status 127); so does `command -V`.  bash writes it to standard error. | POSIX `type`, STDOUT: "information about each operand in an unspecified format".  dash's manual: "Possible resolutions are: shell keyword, alias, shell builtin, command, tracked alias and not found." | `NB:5652` | 90% |

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
