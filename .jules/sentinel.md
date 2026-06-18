## 2024-05-24 - Remove hardcoded path and global variable vulnerability

**Vulnerability:** Found a hardcoded debug log path (`C:\NFMonitor\src\bin\log_debug.txt`) coupled with a global file descriptor `var F: TextFile;` in `routes/route.acbr.nfe.pas`. This exposes sensitive system paths and introduces concurrent access vulnerabilities (race conditions and potential DoS) during concurrent web requests since the file descriptor is global.

**Learning:** Global variables in Horse framework route files can cause serious concurrency issues. Temporary debugging artifacts using `try..except` with hardcoded Windows paths were accidentally left in production code.

**Prevention:** Never use global variables for request handling or file operations. Always remove debugging logic before commits or use structured logging with configurable paths rather than hardcoded `C:\` paths.
