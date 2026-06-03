## 2024-06-03 - [Fix] Legacy debug logging concurrency and path disclosure
**Vulnerability:** A global file descriptor (`var F: TextFile;`) was being used inside a web route (`route.acbr.nfe.pas`) to write to a hardcoded legacy log path (`C:\NFMonitor\src\bin\log_debug.txt`).
**Learning:** Using global file descriptors in web routes introduces race conditions and potential Denial of Service (DoS) during concurrent requests. Furthermore, hardcoded legacy file paths can leak internal directory structures and cause crashes if the path isn't writable.
**Prevention:** Remove legacy `try...except` debug logging blocks and global variables. If logging is needed, use a proper thread-safe logging framework or configurable paths (`RSDefaultCertPath`).
