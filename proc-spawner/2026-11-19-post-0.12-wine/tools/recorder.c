/* recorder.exe: the Windows counterpart of large-subset-runcompare.pl's recorder (one copy per program name, NAME.exe).
   Logs "NAME\037ARG\037ARG..." to %RECLOG% as the Linux recorder does (ANSI argv, so the bytes the caller passed).
   Names in %REALNAMES%: logged, then run as the Linux program of that name (bridge.sh, through files: Wine neither waits
   for a Linux process it starts nor passes its status or pipes, so the input is copied to a file first, the outputs
   are copied back after).  Names in %QUIETNAMES%: run the same way, not logged.  Others: a stand-in that reads what
   the sample feeds it (IN1; not for the programs that never read it, A24 (b)), logs its size and SHA-256, prints
   %STANDIN_OUTPUT%, exits %STANDIN_STATUS% (default 0). */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sha256.h"
#ifndef BRIDGE
#define BRIDGE "Z:\\usr\\bin\\bash /runwin/bridge.sh"
#endif
#define QUIETNAMES "echo printf test [ true false pwd"   /* (not kill: the Linux program would take Windows process IDs for Linux ones) */

static char *xstrdup(const char *s) { size_t n = strlen(s) + 1; char *p = malloc(n); memcpy(p, s, n); return p; }
static char *envv(const char *n) { DWORD k = GetEnvironmentVariableA(n, NULL, 0); if (!k) return NULL;
  char *v = malloc(k + 1); GetEnvironmentVariableA(n, v, k + 1); return v; }
static int inlist(const char *list, const char *n) { if (!list) return 0; size_t l = strlen(n); const char *p = list;
  while (*p) { while (*p == ' ') p++; const char *q = p; while (*q && *q != ' ') q++;
    if ((size_t)(q - p) == l && !strncmp(p, n, l)) return 1; p = q; } return 0; }
static int wr(HANDLE h, const void *b, DWORD n) { DWORD w; while (n) { if (!WriteFile(h, b, n, &w, NULL)) return 0; b = (const char *)b + w; n -= w; } return 1; }
static void appendlog(const char *log, const char *line, size_t len) {
  HANDLE h = CreateFileA(log, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_ALWAYS, 0, NULL);
  if (h == INVALID_HANDLE_VALUE) return; wr(h, line, (DWORD)len); CloseHandle(h); }
/* buffer */
typedef struct { char *p; size_t n, c; } buf_t;
static void badd(buf_t *b, const void *s, size_t n) { if (b->n + n + 1 > b->c) { b->c = (b->n + n + 1) * 2; b->p = realloc(b->p, b->c); }
  memcpy(b->p + b->n, s, n); b->n += n; b->p[b->n] = 0; }
static void bstr(buf_t *b, const char *s) { badd(b, s, strlen(s)); }

/* the run's own standard input (not to be read): the file "stdin" beside RECLOG, else NUL */
static int is_own_stdin(HANDLE in, const char *log) {
  char own[MAX_PATH * 2]; strcpy(own, log); char *s = strrchr(own, '\\'); if (!s) s = strrchr(own, '/');
  if (s) strcpy(s + 1, "stdin"); else strcpy(own, "stdin");
  DWORD t = GetFileType(in);
  HANDLE o = CreateFileA(own, 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, 0, NULL);
  if (o == INVALID_HANDLE_VALUE) return t == FILE_TYPE_CHAR;   /* NUL (no console in these runs) */
  BY_HANDLE_FILE_INFORMATION a, b; int same = 0;
  if (t == FILE_TYPE_DISK && GetFileInformationByHandle(in, &a) && GetFileInformationByHandle(o, &b))
    same = a.dwVolumeSerialNumber == b.dwVolumeSerialNumber && a.nFileIndexHigh == b.nFileIndexHigh && a.nFileIndexLow == b.nFileIndexLow;
  CloseHandle(o); return same; }

static int noinput(const char *n, int argc, char **argv) {
  static const char *ni = " rm rmdir mv cp ln mkdir touch chmod chown chgrp mkfifo mknod unlink link truncate sleep ls basename dirname seq expr readlink realpath stat yes ";
  int i;
  if (inlist(ni, n)) {
    if (!strcmp(n, "rm") || !strcmp(n, "mv") || !strcmp(n, "cp") || !strcmp(n, "ln"))
      for (i = 1; i < argc; i++) { const char *a = argv[i];
        if (!strcmp(a, "--")) break;
        if (!strncmp(a, "--interactive", 13)) return 0;
        if (!strncmp(a, "--", 2)) continue;
        if (a[0] == '-' && (strchr(a + 1, 'i') || strchr(a + 1, 'I'))) return 0; }
    return 1; }
  if (!strcmp(n, "zcat")) { int o = 0, d = 0;
    for (i = 1; i < argc; i++) { const char *a = argv[i];
      if (!d) { if (!strcmp(a, "--")) { d = 1; continue; } if (!strcmp(a, "-")) return 0; if (a[0] == '-' && a[1]) continue; }
      if (!strcmp(a, "-")) return 0; o = 1; }
    return o; }
  return 0; }

static char *unixname(const char *win) {   /* Wine's own conversion (kernel32 export) */
  typedef char *(CDECL *f_t)(LPCWSTR); static f_t f; WCHAR w[MAX_PATH * 2];
  if (!f) f = (f_t)GetProcAddress(GetModuleHandleA("kernel32.dll"), "wine_get_unix_file_name");
  if (!f) return NULL; MultiByteToWideChar(CP_ACP, 0, win, -1, w, MAX_PATH * 2);
  char *u = f(w); return u; }   /* (allocated on the process heap; kept) */

static void wfile(const char *path, const char *b, size_t n) { HANDLE h = CreateFileA(path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
  if (h != INVALID_HANDLE_VALUE) { wr(h, b, (DWORD)n); CloseHandle(h); } }
/* copy a file to a handle; 0 if the handle's writing failed (a closed pipe) */
static int copyout(const char *path, HANDLE h) { HANDLE f = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_DELETE, NULL, OPEN_EXISTING, 0, NULL);
  if (f == INVALID_HANDLE_VALUE) return 1; static char b[65536]; DWORD r; int ok = 1;
  while (ReadFile(f, b, sizeof b, &r, NULL) && r) if (!wr(h, b, r)) { ok = 0; break; }
  CloseHandle(f); return ok; }

static int bridge(const char *name, int argc, char **argv, const char *log) {
  char dir[MAX_PATH * 2], p[MAX_PATH * 2 + 32]; int i;
  /* the request directory beside RECLOG (outside the run's own directory) */
  strcpy(dir, log); char *s = strrchr(dir, '\\'); if (!s) s = strrchr(dir, '/'); if (s) *s = 0; else strcpy(dir, ".");
  sprintf(dir + strlen(dir), "\\br%lu", (unsigned long)GetCurrentProcessId());
  CreateDirectoryA(dir, NULL);
  buf_t b = {0};
  bstr(&b, name); badd(&b, "", 1); for (i = 1; i < argc; i++) { bstr(&b, argv[i]); badd(&b, "", 1); }
  sprintf(p, "%s\\argv", dir); wfile(p, b.p, b.n); b.n = 0;
  char *env = GetEnvironmentStringsA(), *e;
  for (e = env; *e; e += strlen(e) + 1) if (*e != '=') { bstr(&b, e); badd(&b, "", 1); }
  sprintf(p, "%s\\env", dir); wfile(p, b.p, b.n); b.n = 0;
  char cwd[MAX_PATH * 2]; GetCurrentDirectoryA(sizeof cwd, cwd); char *ucwd = unixname(cwd);
  if (ucwd) { sprintf(p, "%s\\cwd", dir); wfile(p, ucwd, strlen(ucwd)); }
  HANDLE in = GetStdHandle(STD_INPUT_HANDLE);
  if (in && in != INVALID_HANDLE_VALUE && !is_own_stdin(in, log)) {   /* the input: all of it, before the program runs */
    sprintf(p, "%s\\in", dir); HANDLE f = CreateFileA(p, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, 0, NULL);
    static char rb[65536]; DWORD r; while (ReadFile(in, rb, sizeof rb, &r, NULL) && r) wr(f, rb, r); CloseHandle(f); }
  else if (!in || in == INVALID_HANDLE_VALUE) { sprintf(p, "%s\\noin", dir); wfile(p, "", 0); }
  sprintf(p, "%s\\go", dir); wfile(p, "", 0);
  char *udir = unixname(dir); if (!udir) return 127;
  char cmd[MAX_PATH * 4]; sprintf(cmd, "%s %s", BRIDGE, udir);
  STARTUPINFOA si = { sizeof si }; PROCESS_INFORMATION pi;
  if (!CreateProcessA(NULL, cmd, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi)) return 127;
  CloseHandle(pi.hThread); CloseHandle(pi.hProcess);
  sprintf(p, "%s\\done", dir);
  while (GetFileAttributesA(p) == INVALID_FILE_ATTRIBUTES) Sleep(2);
  char q[MAX_PATH * 2 + 32]; int st = 0, pipe_ok;
  sprintf(q, "%s\\done", dir); { HANDLE f = CreateFileA(q, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL); char sb[32] = {0}; DWORD r;
    if (f != INVALID_HANDLE_VALUE) { ReadFile(f, sb, 31, &r, NULL); CloseHandle(f); } st = atoi(sb); }
  sprintf(q, "%s\\err", dir); copyout(q, GetStdHandle(STD_ERROR_HANDLE));
  sprintf(q, "%s\\out", dir); pipe_ok = copyout(q, GetStdHandle(STD_OUTPUT_HANDLE));
  for (const char **f = (const char *[]){"argv", "env", "cwd", "in", "noin", "go", "out", "err", "done", NULL}; *f; f++) { sprintf(q, "%s\\%s", dir, *f); DeleteFileA(q); }
  RemoveDirectoryA(dir);
  if (!pipe_ok) return 141;   /* the reader went away: as the program would have died of SIGPIPE on Linux */
  return st; }

/* WINREAL (2026-11-21): when %WINREAL% names a directory holding NAME.exe, run that Windows program in place of the Linux
   one behind the bridge: the same arguments (the rest of this process's own command line, as it was given), the same
   standard handles, its exit status returned.  -1: not there (then the bridge). */
static int winreal(const char *name) {
  char *dir = envv("WINREAL"); if (!dir || !*dir) return -1;
  char path[MAX_PATH * 2]; snprintf(path, sizeof path, "%s\\%s.exe", dir, name);
  if (GetFileAttributesA(path) == INVALID_FILE_ATTRIBUTES) return -1;
  const char *c = GetCommandLineA();   /* skip argv[0] as the CRT reads it: quoted, or up to a blank */
  if (*c == '"') { c++; while (*c && *c != '"') c++; if (*c) c++; } else while (*c && *c != ' ' && *c != '\t') c++;
  size_t cl = strlen(path) + strlen(c) + 4; char *cmd = malloc(cl); snprintf(cmd, cl, "\"%s\"%s", path, c);
  STARTUPINFOA si; PROCESS_INFORMATION pi; memset(&si, 0, sizeof si); si.cb = sizeof si; si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdInput = GetStdHandle(STD_INPUT_HANDLE); si.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE); si.hStdError = GetStdHandle(STD_ERROR_HANDLE);
  if (!CreateProcessA(path, cmd, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi)) return 126;
  WaitForSingleObject(pi.hProcess, INFINITE); DWORD st = 1; GetExitCodeProcess(pi.hProcess, &st);
  CloseHandle(pi.hThread); CloseHandle(pi.hProcess); return (int)st; }

#ifdef RECORDER_UTF8   /* recorder-utf8.exe: the arguments as the CRT parses them in wide characters, as UTF-8 (ours starts programs
                         with CreateProcessW; the ANSI argv would turn them into the code page's bytes) */
static int main_(int argc, char **argv);
int wmain(int argc, wchar_t **wargv) {
  char **argv = calloc(argc + 1, sizeof *argv);
  for (int i = 0; i < argc; i++) { int n = WideCharToMultiByte(CP_UTF8, 0, wargv[i], -1, NULL, 0, NULL, NULL);
    argv[i] = malloc(n ? n : 1); argv[i][0] = 0; WideCharToMultiByte(CP_UTF8, 0, wargv[i], -1, argv[i], n, NULL, NULL); }
  return main_(argc, argv); }
static int main_(int argc, char **argv) {
#else
int main(int argc, char **argv) {
#endif
  char me[MAX_PATH * 2]; GetModuleFileNameA(NULL, me, sizeof me);
  char *n = strrchr(me, '\\'); n = n ? n + 1 : me; size_t l = strlen(n);
  if (l > 4 && !_stricmp(n + l - 4, ".exe")) n[l - 4] = 0;
  char *log = envv("RECLOG"), *real = envv("REALNAMES"); const char *quiet = QUIETNAMES;
  buf_t line = {0}; int i;
  bstr(&line, n); for (i = 1; i < argc; i++) { badd(&line, "\037", 1); bstr(&line, argv[i]); }
  int w;
  char *wq = envv("WINQUIET");   /* runwine.pl -winreal: kill too is not logged, as on Linux (Git's kill takes Windows process IDs) */
  if (log && (inlist(quiet, n) || (wq && *wq && inlist(wq, n)))) return (w = winreal(n)) >= 0 ? w : bridge(n, argc, argv, log);
  if (log && inlist(real, n)) { badd(&line, "\n", 1); appendlog(log, line.p, line.n); return (w = winreal(n)) >= 0 ? w : bridge(n, argc, argv, log); }
  if (log && !noinput(n, argc, argv)) {
    HANDLE in = GetStdHandle(STD_INPUT_HANDLE);
    if (!in || in == INVALID_HANDLE_VALUE) bstr(&line, "\036closed");
    else if (!is_own_stdin(in, log)) {
      static char b[65537]; DWORD r, got = 0; int bad = 0;
      while (got < sizeof b) { if (!ReadFile(in, b + got, sizeof b - got, &r, NULL)) { DWORD e = GetLastError(); if (e != ERROR_BROKEN_PIPE && e != ERROR_HANDLE_EOF) bad = 1; break; }
        if (!r) break; got += r; }
      if (bad && !got) bstr(&line, "\036unreadable");
      else { sha256_t s; char h[65], t[100]; sha256_init(&s); sha256_add(&s, b, got > 65536 ? 65536 : got); sha256_hex(&s, h);
        sprintf(t, "\036%s%s %s", got > 65536 ? "65536" : "", got > 65536 ? "+" : "", h);
        if (got <= 65536) sprintf(t, "\036%lu %s", (unsigned long)got, h);
        bstr(&line, t); } } }
  badd(&line, "\n", 1); if (log) appendlog(log, line.p, line.n);
  char *o = envv("STANDIN_OUTPUT"); if (o && *o) { HANDLE h = GetStdHandle(STD_OUTPUT_HANDLE); wr(h, o, (DWORD)strlen(o)); }
  char *st = envv("STANDIN_STATUS"); return st && *st ? atoi(st) : 0; }
