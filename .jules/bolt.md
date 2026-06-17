## 2026-06-17 - Optimize RTTI Context Creation in TJSONTools
**Learning:** TRttiContext creation initializes and caches RTTI information, making it a relatively expensive operation. Creating it recursively inside functions like `InternalObjToJson` and `JsonToObj` causes redundant allocations (O(N) contexts for N nested objects).
**Action:** Create a single `TRttiContext` in the public entry points (`ObjToJson`, `JsonToObj`) and pass it down as a `const` parameter to recursive internal methods to avoid unnecessary allocations.
