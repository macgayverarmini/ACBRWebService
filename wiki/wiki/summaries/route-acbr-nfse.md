---
title: Route ACBr NFSe Summary
type: summary
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-nfse.md
tags:
  - nfse
  - summary
  - horse
---

# Summary: Route ACBr NFSe

The `route.acbr.nfse` unit registers Horse REST API endpoints for municipal service invoices (NFSe / RPS).

```mermaid
sequenceDiagram
    autonumber
    Client->>Horse: POST /nfse/emitir (JSON Payload)
    Horse->>route.acbr.nfse: PostEmitir(Req, Res, Next)
    route.acbr.nfse->>method.acbr.nfse: TACBRNFSeMethod.EmitirRPS()
    method.acbr.nfse->>ACBr: ACBrNFSeX.Emitir()
    ACBr-->>MunicipalProvider: WebService Request (XML)
    MunicipalProvider-->>ACBr: WebService Response (Lote / Protocolo)
    ACBr-->>route.acbr.nfse: TJSONObject Result
    route.acbr.nfse-->>Client: 200 OK (JSON Response)
```

## Key Highlights

- **Multi-Provider Support**: Interfaces with over 100 Brazilian municipal providers via ACBrNFSeX.
- **RPS Batching & Query**: Supports asynchronous RPS batch submission and subsequent status/lote queries.
- **DANFSe PDF**: Encodes municipal service invoice receipts into Base64 PDF.
