## 2024-05-24 - Predictable Temporary File Names in Pascal

**Vulnerability:** Predictable temporary file names were generated using only the timestamp `FormatDateTime` in `method.acbr.certificados.pas`, leading to potential race conditions or predictable file paths.
**Learning:** `FormatDateTime` alone is not sufficient to guarantee uniqueness and unpredictability.
**Prevention:** Always append a cryptographically secure string or GUID (e.g., `TGuid.NewGuid.ToString`) when generating temporary files.
