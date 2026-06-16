## 2024-05-24 - TRttiContext Allocation Bottleneck
**Learning:** In Free Pascal/Delphi, `TRttiContext.Create` is an expensive operation because it initializes and caches RTTI information. Instantiating it redundantly within loops or recursive serialization/deserialization routines causes severe overhead and O(N) allocations.
**Action:** When using RTTI for deep JSON serialization/deserialization, create the `TRttiContext` once in the public entry points and pass it as a `const` parameter down the call stack to internal recursive functions to maximize performance.
