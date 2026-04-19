## 2024-04-19 - Avoid redundant function evaluation in WriteBuffer arguments

**Learning:** In Pascal/Lazarus, passing an inline function call multiple times as arguments to a procedure (e.g., `WriteBuffer(Func()[1], Length(Func()))`) causes the compiler to evaluate the function redundantly.

**Action:** Store the result of expensive computations in a local variable before using them as arguments in multiple places, such as in `WriteBuffer`. Also, always check that the string is not empty before indexing it at 1.
