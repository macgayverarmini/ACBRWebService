## 2025-02-23 - Predictable Temporary File Names
**Vulnerability:** Timestamp-based temporary file names (e.g., using `FormatDateTime`) lead to predictable filenames, which can cause race conditions or allow an attacker to guess filenames (CWE-377/CWE-379).
**Learning:** In Pascal/Lazarus, appending just the date/time is insufficient for temporary files.
**Prevention:** Use a cryptographically secure string or GUID, like `TGuid.NewGuid.ToString`, to generate unpredictable filenames.
