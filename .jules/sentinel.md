## 2026-06-02 - Information Disclosure & DoS via Hardcoded File Access

**Vulnerability:** Global variable `F: TextFile` used with a hardcoded path (`C:\NFMonitor\src\bin\log_debug.txt`) for debugging in a horse route handler `PostNFe` inside `try...except` blocks without proper concurrency control.

**Learning:** Global variables in concurrent route handlers (like Horse handlers) are a major DoS risk and potential data leak when used for I/O operations because requests overwrite/corrupt each others' file descriptors. Hardcoded paths expose the system layout and create path errors or permission bypasses when the environment changes.

**Prevention:** Never use global variables for state or I/O in route handlers. Remove legacy debug code that relies on local hardcoded paths, or if logging is necessary, use a structured logging framework and configurable paths (`RSDefaultCertPath` equivalents).
