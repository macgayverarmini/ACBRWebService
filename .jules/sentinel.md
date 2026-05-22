## 2024-05-22 - Remove legacy hardcoded path and global TextFile

**Vulnerability:** A global `var F: TextFile;` and legacy debugging statements using `AssignFile(F, 'C:\NFMonitor\src\bin\log_debug.txt');` were present in `routes/route.acbr.nfe.pas`. This creates a path traversal/hardcoded path vulnerability that leaks sensitive environment details, and also causes a concurrency/DoS risk due to the global file descriptor being accessed concurrently by different web requests.

**Learning:** Global variables for file descriptors in web routes lead to concurrency issues. Hardcoded absolute paths (especially ones pointing to specific directories like `C:\NFMonitor`) leak environmental information and break portability and security.

**Prevention:** Never use global file descriptors in web handlers. Remove legacy debugging blocks from production code. If logging is needed, use standard framework logging facilities or safe, configurable local paths.
