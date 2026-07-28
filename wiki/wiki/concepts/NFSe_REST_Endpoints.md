---
title: NFSe REST Endpoints & Pipeline
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-nfse.md
tags:
  - nfse
  - endpoints
  - pipeline
---

# NFSe REST Endpoints & Pipeline

The **NFSe REST Pipeline** in ACBRWebService handles municipal service invoices and Recibo Provisório de Serviços (RPS) via [[entities/ACBr]].

```mermaid
flowchart TD
    Submit[POST /nfse/emitir] --> Provider{Municipal Provider}
    Provider -->|Asynchronous| Query[POST /nfse/consultarlote]
    Provider -->|Synchronous| DANFSe[POST /nfse/danfse (PDF)]
    Query --> DANFSe
    DANFSe --> Cancel[POST /nfse/cancelar]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/nfse/modelo/config` | JSON schema for NFSe municipal provider config |
| `GET` | `/nfse/modelo/emitir` | JSON schema for RPS submission payload |
| `POST` | `/nfse/emitir` | Transmits RPS batch to municipal web service |
| `POST` | `/nfse/consultarlote` | Queries processing status of submitted RPS batch |
| `POST` | `/nfse/danfse` | Converts NFSe XML into Base64 PDF receipt |
| `POST` | `/nfse/cancelar` | Requests cancellation of issued municipal NFSe |

## Related Pages
- [[ACBRWebService_Architecture]]
- [[route-acbr-nfse]]
- [[NFe_REST_Endpoints]]
- [[ACBr]]
