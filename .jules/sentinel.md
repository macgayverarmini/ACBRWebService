## 2025-04-25 - Predictable Temporary File Names in Certificates Processing
**Vulnerability:** The `method.acbr.certificados.pas` file uses predictable temporary file names containing only a prefix and `FormatDateTime(RSDateTimeFormat, Now)` before saving decoded certificate buffers to disk.
**Learning:** Temporary files without strong randomness/entropy in their names can lead to race conditions or allow unauthorized local processes to predict file paths and potentially interfere with, overwrite, or access sensitive certificate contents.
**Prevention:** To prevent race conditions and predictable temporary file names in Pascal, always append a cryptographically secure string or GUID (e.g., `TGuid.NewGuid.ToString`) to the filename, as explicitly advised in memory.
