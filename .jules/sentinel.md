## 2024-05-11 - Global File Descriptors in Web Routes
**Vulnerability:** A global file descriptor (`var F: TextFile;`) was declared in `routes/route.acbr.nfe.pas` and used within a web route implementation along with hardcoded paths (`C:\NFMonitor\src\bin\log_debug.txt`).
**Learning:** Using global variables for file handling in web frameworks (like Horse) creates concurrency issues/race conditions, leading to potential Denial of Service (DoS) during concurrent requests. Furthermore, hardcoded file paths expose internal system directory structures, risking information disclosure.
**Prevention:** Avoid global state for I/O operations in route handlers. Instead, use localized, thread-safe logging mechanisms and configurable paths, and never commit legacy/testing code into production routes.
