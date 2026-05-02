## 2024-05-02 - Optimize TRttiContext allocation in JSON conversion
**Learning:** In FPC/Delphi, `TRttiContext.Create` is relatively expensive because it sets up the context for reflection. Creating and destroying it repeatedly inside recursive serialization and deserialization functions (like converting JSON to nested objects) creates significant overhead.
**Action:** Always create `TRttiContext` once in the public entry points of serialization/deserialization utilities and pass it as a `const` parameter down to internal recursive methods.
