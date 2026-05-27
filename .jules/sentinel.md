## 2024-05-27 - Removal of Global File Descriptor in Web Routes

**Vulnerability:**
Global variable `var F: TextFile;` declared in the implementation section of `routes/route.acbr.nfe.pas`, combined with hardcoded debug file paths `C:\NFMonitor\src\bin\log_debug.txt` and generic `try..except` suppression.

**Learning:**
Declaring global file descriptors in web frameworks like Horse leads to concurrency issues/race conditions, as multiple concurrent requests would attempt to `AssignFile`, `Rewrite`/`Append`, and write to the same global descriptor simultaneously, potentially corrupting logs or causing file lock crashes (DoS). Additionally, the use of hardcoded debug paths exposes path logic and could leak sensitive information if debug log files are compromised.

**Prevention:**
Always keep variables, particularly file descriptors and objects, within the scope of the method handling the HTTP request. Never commit temporary/hardcoded file paths or raw `TextFile` I/O blocks into production route handlers. Use standard framework or systemic logging configurations instead of direct file manipulations within routes.
