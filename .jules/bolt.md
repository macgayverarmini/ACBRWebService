## 2025-02-18 - Optimize Base64 Stream Conversions
**Learning:** In Lazarus/FPC, passing the same inline function call multiple times as arguments to a procedure (e.g., `WriteBuffer(Func()[1], Length(Func()))`) causes the compiler to evaluate the function redundantly.
**Action:** Store the result of expensive computations in a local variable before use. Also, avoid unnecessary string-to-bytes-to-string round-trips when interacting with functions that natively accept string inputs.
