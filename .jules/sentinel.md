## 2024-05-09 - Fix DoS risk due to global file descriptor in HTTP route

**Vulnerability:** A global file descriptor (`var F: TextFile;`) and hardcoded file path (`C:\NFMonitor\src\bin\log_debug.txt`) were used to write debug logs inside an HTTP route handler (`PostNFe`).
**Learning:** Using global state such as file descriptors across concurrent web requests can lead to race conditions, I/O blocking, and Denial of Service (DoS) when multiple requests attempt to open or write to the same file simultaneously. The hardcoded path also created a directory traversal/path issue on systems without that specific directory structure.
**Prevention:** Avoid defining variables globally within web route units. Ensure any logging uses proper concurrency-safe logging mechanisms (e.g. thread-safe log queues) and avoid writing raw text files directly in request handlers. Hardcoded paths should be avoided in favor of parameterized configurations.
