## 2024-05-17 - Avoid Duplicate Inline Evaluation and TEncoding Round-trips in Free Pascal

**Learning:** When passing inline function calls as parameters to a procedure like `WriteBuffer(Func()[1], Length(Func()))`, the Free Pascal compiler evaluates the function `Func()` twice. For expensive functions like Base64 encoding, this creates significant overhead. Furthermore, unnecessary conversion between strings and byte arrays (`TBytes`) using `TEncoding.UTF8.GetBytes` or `GetString` causes redundant memory allocations.

**Action:** Always store the result of expensive computations in a local string variable before passing it to procedures that require its length and data. In Free Pascal/Delphi, optimize stream reads/writes by passing the native string index directly (e.g., `AStream.ReadBuffer(str[1], Size)`) instead of routing through intermediate `TBytes` arrays.
