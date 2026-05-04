## 2024-05-24 - Remove Hardcoded Debugging Path
**Vulnerability:** Hardcoded absolute path `C:\NFMonitor\src\bin\log_debug.txt` used for legacy debug logging in `routes/route.acbr.nfe.pas`.
**Learning:** Legacy debug logging blocks with hardcoded absolute file paths can leak sensitive internal directory structures and result in runtime errors/crashes across environments.
**Prevention:** Use standardized logging mechanisms and configurable paths (e.g. `RSDefaultCertPath` or similar configuration). Always remove local debug blocks before committing.
