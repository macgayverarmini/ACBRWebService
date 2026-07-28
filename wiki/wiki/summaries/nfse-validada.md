---
title: NFSe Validation & Architecture Memo Summary
type: summary
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/articles/nfse-validada.md
tags:
  - nfse
  - validation
  - summary
---

# Summary: NFSe Validation & Architecture Memo

Technical memo detailing critical fixes in the ACBrNFSeX module:
1. **RPS Collection Mapping**: Fixed RTTI deserialization by calling `NotasFiscais.New` prior to object mapping, avoiding the *"Nenhum RPS adicionado"* error.
2. **In-Memory Base64 PFX Loading**: Direct Base64 certificate decoding into memory (`DadosPFXBase64`).
3. **XML ⇄ JSON Conversion**: Dual-directional endpoints `/nfse/nfse-from-xml` and `/nfse/nfse-to-xml`.
4. **National Environment DFe**: Validated distribution downloading via SERPRO / ADN national portal returning 50 documents.
