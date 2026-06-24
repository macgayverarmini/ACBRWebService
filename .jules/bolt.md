## 2024-06-24 - Optimize Stream Operations

**Learning:** In Free Pascal/Lazarus, allocating intermediate `TBytes` arrays and using `TEncoding.UTF8.GetString` or `GetBytes` is unnecessary when working with streams and string data, leading to extra memory allocations and copying. Additionally, passing an expensive function call (like `EncodeStringBase64`) twice as inline arguments to a procedure evaluates it redundantly.

**Action:** Read directly into native string types using `ReadBuffer(str[1], AStream.Size)` and ensure the stream size is checked for `> 0` first. When passing the result of an expensive function, cache it in a local variable before using it as a buffer and length.
