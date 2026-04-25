## 2024-05-19 - Avoid TEncoding roundtrips for Stream-to-String in Pascal
**Learning:** Using `TEncoding.UTF8.GetBytes` and `TEncoding.UTF8.GetString` to move string data to and from a `TMemoryStream` creates unnecessary intermediate `TBytes` arrays. In FPC/Delphi, native strings can be mapped directly to stream buffers.
**Action:** Use `AStream.ReadBuffer(str[1], AStream.Size)` and `AStream.WriteBuffer(str[1], Length(str))` to interact with streams, bypassing memory-heavy array allocations.
