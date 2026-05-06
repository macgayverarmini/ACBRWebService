
## 2024-05-18 - Memory-Efficient Stream to String Encoding in Pascal
**Learning:** Functions like `TEncoding.UTF8.GetBytes` and `TEncoding.UTF8.GetString` allocate intermediate `TBytes` arrays that are unnecessary when reading/writing from `TMemoryStream` to standard string variables, causing performance penalties and memory fragmentation. Additionally, passing the result of an inline method call like `EncodeStringBase64` to `WriteBuffer`'s pointer and `Length()` arguments simultaneously double-evaluates the expensive encoding.
**Action:** When handling streams with strings, use `SetLength(Str, Stream.Size)` and read/write buffer operations natively with `Str[1]`. Ensure expensive function outputs are pre-computed and stored in local string variables before parameter passing.
