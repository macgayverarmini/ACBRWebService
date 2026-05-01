## 2026-05-01 - Prevent Hardcoded Debug Path Info Leaks
**Vulnerability:** The code wrote sensitive API configuration states and HTTP bodies as plaintext to hardcoded file paths (e.g., `C:\NFMonitor\src\bin\log_debug.txt`), which leaks secrets to local disk and risks app crashes or permissions errors if the hardcoded path is unavailable.
**Learning:** Temporary debugging logs or ad-hoc "SaveToFile" calls from development are often accidentally checked into main. These leak PII, certificates, or configuration files.
**Prevention:** Use established logging frameworks rather than direct `AssignFile` / `SaveToFile` with hardcoded system paths, and implement static analysis to alert on file path strings and file creation commands directly in production logic paths.
