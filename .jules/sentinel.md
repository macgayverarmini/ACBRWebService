## 2024-04-24 - Fix predictable temporary file generation
**Vulnerability:** Used `FormatDateTime` to generate temporary file names for certificates, which creates predictable names and can lead to race conditions or file overwrite vulnerabilities.
**Learning:** Always use a cryptographically secure string or GUID (e.g., `TGuid.NewGuid.ToString`) when generating temporary files in Pascal.
**Prevention:** Do not use timestamp-only generation (`FormatDateTime`). Append a GUID to ensure uniqueness and security.
