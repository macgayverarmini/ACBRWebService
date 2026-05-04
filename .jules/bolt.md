## 2024-05-24 - Avoid TEncoding.UTF8 byte arrays for Stream strings
**Learning:** `TEncoding.UTF8.GetBytes` and `TEncoding.UTF8.GetString` create unnecessary byte array allocations when doing Stream string operations in FPC/Lazarus. Strings can be cast directly.
**Action:** Use native string indexing `str[1]` directly with `ReadBuffer` and `WriteBuffer` to avoid `TBytes` overhead.
