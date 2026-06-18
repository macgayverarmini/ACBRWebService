## 2024-06-25 - Object-to-JSON Serialization Optimization
**Learning:** Initializing TRttiContext per property evaluation or nested object in `tools/jsonconvert.pas` creates significant O(N) allocation and garbage collection overhead during JSON conversion.
**Action:** Inject TRttiContext from public API methods into internal recursive procedures as a `const` reference, instantiating it exactly once per top-level serialization operation.
