
## 2024-05-18 - Optimize Stream Read/Write via Native Strings in Lazarus/FPC
**Learning:** Using `TBytes` combined with `TEncoding.UTF8.GetString` or `GetBytes` is unnecessary when working with streams and native strings in Pascal/FPC. It creates an intermediate heap allocation and performs a redundant copy.
**Action:** When interacting with streams in Lazarus/FPC, use native string types directly with `TMemoryStream.ReadBuffer` and `WriteBuffer` (e.g., `AStream.ReadBuffer(str[1], AStream.Size)`) instead of allocating intermediate `TBytes` arrays. Always verify length is greater than 0 before indexing.
