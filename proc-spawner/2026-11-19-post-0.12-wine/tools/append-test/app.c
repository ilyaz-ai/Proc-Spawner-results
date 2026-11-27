/* app.exe FILE TAG N: N lines "TAG <i>\n" appended to FILE through a handle opened with FILE_APPEND_DATA only, as
   recorder.exe writes its log; one WriteFile per line */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
int main(int argc, char **argv) {
  HANDLE h = CreateFileA(argv[1], FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL, OPEN_ALWAYS, 0, NULL);
  if (h == INVALID_HANDLE_VALUE) return 1;
  int n = atoi(argv[3]); char b[64];
  for (int i = 0; i < n; i++) { int l = sprintf(b, "%s %d\n", argv[2], i); DWORD w; WriteFile(h, b, l, &w, NULL); }
  CloseHandle(h); return 0; }
