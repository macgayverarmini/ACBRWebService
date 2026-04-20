## 2026-04-20 - Fix predictable temporary file names and race conditions
**Vulnerability:** The application was generating predictable temporary file names by concatenating a constant prefix with a timestamp. This allows for race conditions where an attacker could pre-create or modify files to intercept data or escalate privileges.
**Learning:** In Pascal/Lazarus, appending just the date-time to a fixed path leads to predictable temporary files which is a significant security risk for data processing workloads.
**Prevention:** Always append a cryptographically secure string or GUID (e.g., `TGuid.NewGuid.ToString`) to the temporary filename to ensure uniqueness and block predictability.
