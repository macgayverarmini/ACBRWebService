## 2024-05-18 - Information Disclosure via Hardcoded Legacy Debug Logs
**Vulnerability:** Legacy debug statements (`AssignFile`, `SaveToFile`) using hardcoded absolute file paths like `C:\NFMonitor\src\bin\log_debug.txt` within web routes and method implementations.
**Learning:** These paths can expose execution flow, sensitive timing data, and internal system structure when exceptions occur or if log files are globally readable on a Windows deployment, presenting an information disclosure vulnerability. They often get forgotten and committed during debugging.
**Prevention:** Remove all such hardcoded file logging within production code. Use a centralized logging framework or configurable paths that map appropriately to container/runtime variables instead of literal C-drive directories.
