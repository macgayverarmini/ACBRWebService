---
title: Lazarus RTTI & JSON Serialization Engine
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/articles/nfse-validada.md
  - raw/notes/tools-and-utilities.md
tags:
  - rtti
  - json
  - serialization
  - lazarus
---

# Lazarus RTTI & JSON Serialization Engine

The **JSON RTTI Serialization Engine** (`TJSONTools` in `tools/jsonconvert.pas`) is the core mechanism enabling ACBRWebService to transform HTTP JSON request payloads directly into Pascal `TObject` properties.

```mermaid
flowchart TD
    JSON[HTTP Body JSON Payload] --> TJSONTools[TJSONTools.JsonToObj]
    TJSONTools --> RTTI[Lazarus FPC RTTI Reflection]
    RTTI --> ObjInstance[ACBr Component Object Instance]
```

## Key Mechanisms

1. **Object Instantiation (`NotasFiscais.New`)**: For collection properties (such as `facbr.NotasFiscais`), items must be explicitly allocated via `.New` before RTTI deserialization to prevent empty collection errors.
2. **In-Memory Base64 PFX Certificates**: Accepts `DadosPFXBase64` directly into `facbr.Configuracoes.Certificados.DadosPFX` without writing temporary PFX files to disk.
3. **Dual-Directional XML ⇄ JSON**: Converts XML Base64 strings to JSON via `nfse-from-xml` and serializes JSON back to XML via `nfse-to-xml`.

## Related Pages
- [[ACBRWebService_Architecture]]
- [[Lazarus_FPC]]
- [[NFSe_REST_Endpoints]]
- [[tools-and-utilities]]
