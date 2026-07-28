---
title: Route ACBr CTe Summary
type: summary
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-cte.md
tags:
  - cte
  - summary
  - horse
---

# Summary: Route ACBr CTe

The `route.acbr.cte` unit registers Horse REST API endpoints for freight and cargo transportation invoices (CTe - Modelo 57).

```mermaid
sequenceDiagram
    autonumber
    Client->>Horse: POST /cte (JSON Payload)
    Horse->>route.acbr.cte: PostCTe(Req, Res, Next)
    route.acbr.cte->>method.acbr.cte: TACBRCTeMethod.EmitirCTe()
    method.acbr.cte->>ACBr: ACBrCTe.Enviar()
    ACBr-->>SEFAZ: WebService Request (XML)
    SEFAZ-->>ACBr: WebService Response (ProtCTe)
    ACBr-->>route.acbr.cte: TJSONObject Result
    route.acbr.cte-->>Client: 200 OK (JSON Response)
```

## Key Highlights

- **Freight Invoice Lifecycle**: Handles CTe emission, SEFAZ status check, and cancellation.
- **DACTE Generation**: Converts CTe XML into Base64 PDF formatted DACTE receipt via FortesReport/PowerPDF.
