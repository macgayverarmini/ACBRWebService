
## 2024-05-18 - Native string buffers and inline evaluation redundancy
**Learning:** In Lazarus/FPC, passing the same inline function call multiple times as arguments (e.g., `Result.WriteBuffer(func()[1], Length(func()))`) causes the compiler to evaluate the function redundantly. Also, using intermediate `TBytes` arrays via `TEncoding.UTF8` for streams natively dealing with strings introduces unnecessary round-trips.
**Action:** Store the result of expensive computations in a local variable before use, and use native string types directly with `TMemoryStream.ReadBuffer` and `WriteBuffer` (e.g., `AStream.ReadBuffer(str[1], AStream.Size)`) for better performance and memory efficiency.
