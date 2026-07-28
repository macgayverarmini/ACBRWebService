---
title: Route ACBr NFe Summary
type: summary
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-nfe.md
tags:
  - nfe
  - endpoints
  - horse
---

# Summary: Route ACBr NFe

The `route.acbr.nfe` unit registers all Horse HTTP routes for managing NFe (Nota Fiscal Eletrônica). It bridges JSON payloads from client applications to the underlying [[entities/ACBr]] NFe component via [[entities/Horse_Framework]] procedures.

```mermaid
sequenceDiagram
    autonumber
    Client->>Horse: POST /nfe (JSON Payload)
    Horse->>route.acbr.nfe: PostNFe(Req, Res, Next)
    route.acbr.nfe->>method.acbr.nfe: TACBRNFeMethod.EmitirNFe()
    method.acbr.nfe->>ACBr: ACBrNFe.Enviar()
    ACBr-->>SEFAZ: WebService Request (XML)
    SEFAZ-->>ACBr: WebService Response (ProtNFe)
    ACBr-->>route.acbr.nfe: TJSONObject Result
    route.acbr.nfe-->>Client: 200 OK (JSON Response)
```

## Key Capabilities

- **Emission & Status**: Query SEFAZ availability (`PostStatusServicoNFe`) and submit NFe batches (`PostNFe`).
- **Printing / DANFE**: Convert XML to PDF DANFE encoded in Base64 (`PostDANFe`).
- **Events & Distribution**: Handle NFe events (`PostEventos`) and query distribution NSUs (`PostDistribuicao`).
- **Number Management**: Handle number cancellation (`PostCancelamentoNFe`) and inutilization (`PostInutilizacaoNFe`).
