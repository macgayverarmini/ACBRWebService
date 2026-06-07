## 2024-05-24 - Avoid TEncoding.UTF8 String/Bytes Round-trips
**Learning:** In Lazarus/FPC, creating intermediate `TBytes` arrays via `TEncoding.UTF8.GetString` and `TEncoding.UTF8.GetBytes` when interacting with streams is inefficient. `TStream.ReadBuffer` and `WriteBuffer` can directly read into and write from string memory.
**Action:** Use native string types directly with `TMemoryStream.ReadBuffer` and `WriteBuffer` (e.g., `AStream.ReadBuffer(str[1], AStream.Size)`) instead of allocating intermediate `TBytes` arrays via `TEncoding.UTF8` for better performance and memory efficiency.
