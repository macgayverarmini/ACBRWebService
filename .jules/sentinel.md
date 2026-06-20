## 2024-06-20 - Fix global file descriptor concurrency vulnerability
**Vulnerability:** A global file descriptor `var F: TextFile;` was used in `route.acbr.nfe.pas` across a concurrent Horse route, which leads to race conditions and Denial-of-Service when multiple requests trigger the file logging logic simultaneously. Additionally, the log file hardcoded a Windows path (`C:\NFMonitor\src\bin\log_debug.txt`).
**Learning:** Avoid declaring global file descriptors or similar stateful variables in web request handling logic.
**Prevention:** Avoid legacy file logging using `AssignFile` in web apps and favor standard loggers. Also, do not hardcode absolute system paths.
