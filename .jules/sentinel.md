## 2025-04-30 - Predictable Temporary File Names in Pascal
**Vulnerability:** Temporary files generated using timestamps (e.g., `FormatDateTime`) are highly predictable, which can allow an attacker to hijack the temp file path, leading to race conditions or arbitrary file read/write issues if temp files are not properly isolated.
**Learning:** In the Pascal ecosystem, particularly with `TBytesStream` or when writing secrets (like certificates) to disk temporarily, using a timestamp string is insufficient for uniqueness and security against local attackers.
**Prevention:** Avoid `FormatDateTime` for temporary filename uniqueness. Instead, append a cryptographically secure random string or use a GUID, such as `TGuid.NewGuid.ToString`, to prevent race conditions and predictable file names.
