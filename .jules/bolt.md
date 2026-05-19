## 2024-05-19 - Optimize stream conversions avoiding intermediate TBytes

**Learning:** In Lazarus/FPC, interacting with streams (like `TMemoryStream`) using intermediate `TBytes` arrays allocated via `TEncoding.UTF8.GetBytes` and `TEncoding.UTF8.GetString` introduces redundant allocations and performance overhead.

**Action:** Use native string types directly with `AStream.ReadBuffer` and `AStream.WriteBuffer` (e.g., `AStream.ReadBuffer(str[1], AStream.Size)`) to avoid intermediate O(N) allocation round-trips. Always ensure strings are not empty (e.g., `Length(str) > 0` or `Size > 0`) before accessing index 1 to prevent out-of-bounds exceptions.