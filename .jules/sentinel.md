## 2024-04-29 - Predictable Temporary File Names

**Vulnerability:** In `method.acbr.certificados.pas`, temporary certificate files were being created with names generated solely by a predictable timestamp `FormatDateTime(RSDateTimeFormat, Now)`. This leaves the system open to race conditions or predictable temporary file name vulnerabilities (e.g., symlink attacks or arbitrary file overwrite) since the time of execution is easily guessable.
**Learning:** Hardcoded strings or mere timestamping are insufficient to guarantee uniqueness for temporary file names, particularly when running in concurrency-friendly environments like microservices or APIs.
**Prevention:** To prevent this, always combine the current timestamp with an unpredictable component like a cryptographically secure string or GUID (e.g., `TGuid.NewGuid.ToString`) when generating temporary files.
