## 2024-05-21 - TRttiContext O(1) Allocation Optimization
**Learning:** In Free Pascal/Delphi, `TRttiContext.Create` is an expensive operation because it initializes and caches RTTI info. Repeated creation during recursive operations (like JSON serialization/deserialization) causes performance bottlenecks.
**Action:** When performing recursive RTTI reflection, always instantiate `TRttiContext` once at the entry point and pass it recursively to internal functions to avoid redundant allocations.
