## 2024-04-18 - Prevented redundant function evaluation in WriteBuffer arguments
**Learning:** In Pascal/Lazarus, passing the same inline function call multiple times as arguments to a procedure (e.g., `Result.WriteBuffer(Func()[1], Length(Func()))`) causes the compiler to evaluate the function redundantly.
**Action:** Store the result of expensive computations (like `EncodeStringBase64`) in a local variable before use and check if the string is empty before accessing its first element via index 1 (since string indexing in Pascal/Delphi is 1-based).
