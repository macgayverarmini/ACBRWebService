## 2024-05-18 - Exposed Hardcoded Debug Paths
**Vulnerability:** Found legacy Pascal `try..except` debugging blocks using `AssignFile` to write logs to hardcoded Windows paths (e.g., `C:\NFMonitor\src\bin\log_debug.txt`) in `routes/route.acbr.nfe.pas`.
**Learning:** Legacy debug code can introduce path traversal risks or expose local filesystem structures, acting as an information disclosure vulnerability, especially when these exceptions are caught and swallowed, masking the behavior.
**Prevention:** Avoid committing debug logging to fixed system paths. Use centralized configurable logging routines with abstract paths and proper cleanup before creating pull requests.
