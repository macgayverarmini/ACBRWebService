## 2026-05-26 - Avoid Redundant Function Calls and Intermediate Arrays in Free Pascal

**Learning:** In Lazarus/FPC, passing the result of an inline function call multiple times as arguments to another procedure (like `WriteBuffer(Func()[1], Length(Func()))`) causes the compiler to evaluate the function redundantly. Additionally, allocating intermediate `TBytes` arrays via `TEncoding.UTF8.GetBytes` and `TEncoding.UTF8.GetString` for stream reads/writes introduces unnecessary overhead and memory allocation, compared to using native string types directly with `TMemoryStream.ReadBuffer` and `WriteBuffer`.

**Action:** When performing I/O on streams, use native strings directly with `ReadBuffer` and `WriteBuffer` (e.g., `AStream.ReadBuffer(str[1], AStream.Size)`). Always store the result of expensive computations (such as Base64 encoding) in a local variable before using it multiple times.
