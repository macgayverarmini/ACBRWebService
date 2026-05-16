## 2024-05-16 - Optimize TRttiContext allocations in JSON serialization
**Learning:** In Free Pascal/Delphi, TRttiContext creation is relatively expensive because it initializes and caches RTTI information. Repeatedly creating it in recursive serialization/deserialization loops causes redundant O(N) allocations, degrading performance.
**Action:** Create TRttiContext exactly once at public entry points and pass it as a const parameter to internal recursive methods to convert O(N) allocations into O(1).
