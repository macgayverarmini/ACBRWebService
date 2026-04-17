## 2024-04-17 - Avoid Duplicate Inline Function Evaluation in Pascal

**Learning:** When passing inline function calls as arguments to Pascal procedures (like `Result.WriteBuffer(Encode(...)[1], Length(Encode(...)))`), the compiler will evaluate the function redundantly for each call. In `streamtools.pas`, this caused an expensive `O(N)` base64 encoding to execute twice.

**Action:** Always store the result of expensive transformations or computations (like encoding or parsing) in a local variable before using it multiple times in parameters or conditions.
