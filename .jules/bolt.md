## 2026-04-28 - Avoid Intermediate TBytes Allocation
**Learning:** In Lazarus/FPC, using intermediate TBytes arrays with TEncoding.UTF8 for string to stream conversions causes unnecessary memory allocations and performance degradation, because string types can interact natively with stream ReadBuffer/WriteBuffer.
**Action:** Use native string types directly with TMemoryStream.ReadBuffer and WriteBuffer (e.g., `AStream.ReadBuffer(str[1], AStream.Size)`) and ensure string indexes are 1-based and non-empty.
