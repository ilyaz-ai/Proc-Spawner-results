/* runner.exe: runs one sample at a time for large-subset-runwine.pl, under Wine.  Reads lines from its standard input,
   each the Windows path of a request file: NUL-separated cwd, stdin file, stdout file, stderr file, timeout (ms), after
   (ms), the command line, then NAME=VALUE entries (the whole environment).  The process runs in a job object of its own
   (as the Linux runner's prlimit: 10 s of CPU per process, 400 processes); after timeout ms the job is ended (status 124,
   as timeout(1)); once the process has ended, what is left of the job gets up to "after" ms (A18), then is ended
   ("killed").  Answers one line per request: "STATUS AFTER" (AFTER: - or killed), or "error TEXT". */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static WCHAR *u8w(const char *s) { int n = MultiByteToWideChar(CP_UTF8, 0, s, -1, NULL, 0); WCHAR *w = malloc(n * sizeof(WCHAR));
  MultiByteToWideChar(CP_UTF8, 0, s, -1, w, n); return w; }
static void reply(const char *s) { DWORD w; HANDLE o = GetStdHandle(STD_OUTPUT_HANDLE); WriteFile(o, s, (DWORD)strlen(s), &w, NULL); }

static void one(const char *req) {
  HANDLE f = CreateFileA(req, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);
  if (f == INVALID_HANDLE_VALUE) { reply("error request\n"); return; }
  DWORD sz = GetFileSize(f, NULL), r; char *b = malloc(sz + 2); ReadFile(f, b, sz, &r, NULL); CloseHandle(f); b[sz] = 0; b[sz + 1] = 0;
  char *fld[7]; char *p = b; int i;
  for (i = 0; i < 7; i++) { fld[i] = p; p += strlen(p) + 1; if (p > b + sz) { reply("error fields\n"); free(b); return; } }
  /* the environment block: UTF-16, sorted as Windows keeps it */
  size_t en = 0; char *q; for (q = p; q < b + sz && *q; q += strlen(q) + 1) en++;
  WCHAR **ev = malloc((en + 1) * sizeof *ev); size_t k = 0, tot = 1;
  for (q = p; q < b + sz && *q; q += strlen(q) + 1) { ev[k] = u8w(q); tot += wcslen(ev[k]) + 1; k++; }
  for (size_t x = 0; x < en; x++) for (size_t y = x + 1; y < en; y++) if (_wcsicmp(ev[y], ev[x]) < 0) { WCHAR *t = ev[x]; ev[x] = ev[y]; ev[y] = t; }
  WCHAR *env = malloc(tot * sizeof(WCHAR)), *e = env;
  for (k = 0; k < en; k++) { wcscpy(e, ev[k]); e += wcslen(ev[k]) + 1; free(ev[k]); } *e = 0; free(ev);
  SECURITY_ATTRIBUTES sa = { sizeof sa, NULL, TRUE };
  WCHAR *win = u8w(fld[1]), *wout = u8w(fld[2]), *werr = u8w(fld[3]), *wcwd = u8w(fld[0]), *wcmd = u8w(fld[6]);
  HANDLE hin = CreateFileW(win, GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, &sa, OPEN_EXISTING, 0, NULL);
  HANDLE hout = CreateFileW(wout, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, &sa, TRUNCATE_EXISTING, 0, NULL);
  HANDLE herr = CreateFileW(werr, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, &sa, TRUNCATE_EXISTING, 0, NULL);
  if (hin == INVALID_HANDLE_VALUE || hout == INVALID_HANDLE_VALUE || herr == INVALID_HANDLE_VALUE) { reply("error stdio\n"); goto out; }
  HANDLE job = CreateJobObjectW(NULL, NULL);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION li; memset(&li, 0, sizeof li);
  li.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE | JOB_OBJECT_LIMIT_PROCESS_TIME | JOB_OBJECT_LIMIT_ACTIVE_PROCESS;
  li.BasicLimitInformation.PerProcessUserTimeLimit.QuadPart = 10LL * 10000000;
  li.BasicLimitInformation.ActiveProcessLimit = 400;
  SetInformationJobObject(job, JobObjectExtendedLimitInformation, &li, sizeof li);
  STARTUPINFOW si; memset(&si, 0, sizeof si); si.cb = sizeof si; si.dwFlags = STARTF_USESTDHANDLES;
  si.hStdInput = hin; si.hStdOutput = hout; si.hStdError = herr;
  PROCESS_INFORMATION pi;
  if (!CreateProcessW(NULL, wcmd, NULL, NULL, TRUE, CREATE_SUSPENDED | CREATE_UNICODE_ENVIRONMENT, env, wcwd, &si, &pi)) {
    char t[64]; sprintf(t, "error create %lu\n", GetLastError()); reply(t); CloseHandle(job); goto out; }
  AssignProcessToJobObject(job, pi.hProcess); ResumeThread(pi.hThread); CloseHandle(pi.hThread);
  CloseHandle(hin); CloseHandle(hout); CloseHandle(herr); hin = hout = herr = INVALID_HANDLE_VALUE;
  DWORD st; const char *after = "-";
  if (WaitForSingleObject(pi.hProcess, (DWORD)atol(fld[4])) == WAIT_TIMEOUT) {
    TerminateJobObject(job, 124); WaitForSingleObject(pi.hProcess, 5000); st = 124; }
  else {
    GetExitCodeProcess(pi.hProcess, &st);
    DWORD end = GetTickCount() + (DWORD)atol(fld[5]);
    for (;;) { JOBOBJECT_BASIC_ACCOUNTING_INFORMATION ai; memset(&ai, 0, sizeof ai);
      if (!QueryInformationJobObject(job, JobObjectBasicAccountingInformation, &ai, sizeof ai, NULL) || !ai.ActiveProcesses) break;
      if ((LONG)(GetTickCount() - end) >= 0) { TerminateJobObject(job, 137); after = "killed"; Sleep(50); break; }
      Sleep(50); } }
  CloseHandle(pi.hProcess); CloseHandle(job);
  { char t[64]; sprintf(t, "%lu %s\n", (unsigned long)st, after); reply(t); }
out:
  if (hin != INVALID_HANDLE_VALUE) CloseHandle(hin); if (hout != INVALID_HANDLE_VALUE) CloseHandle(hout); if (herr != INVALID_HANDLE_VALUE) CloseHandle(herr);
  free(win); free(wout); free(werr); free(wcwd); free(wcmd); free(env); free(b); }

int main(void) {
  HANDLE in = GetStdHandle(STD_INPUT_HANDLE); char line[4096]; size_t n = 0; char c; DWORD r;
  SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
  while (ReadFile(in, &c, 1, &r, NULL) && r) {
    if (c == '\n') { line[n] = 0; if (n) one(line); n = 0; } else if (n < sizeof line - 1) line[n++] = c; }
  return 0; }
