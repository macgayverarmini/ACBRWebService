---
title: NFe REST Endpoints & Pipeline
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-nfe.md
tags:
  - nfe
  - endpoints
  - pipeline
---

# NFe REST Endpoints & Pipeline

The **NFe REST Pipeline** in ACBRWebService handles the lifecycle of Electronic Fiscal Invoices (Modelo 55 and 65 / NFCe) in Brazil via [[entities/ACBr]] components.

```mermaid
flowchart TD
    Config[GET /nfe/modelo/config] --> Submit[POST /nfe (Emission)]
    Submit --> SEFAZ{SEFAZ Processing}
    SEFAZ -->|Authorized| DANFE[POST /nfe/danfe (PDF Generation)]
    SEFAZ -->|Denied/Error| Inutilize[POST /nfe/inutilizacao]
    DANFE --> Event[POST /nfe/eventos (Correction/Manifest)]
    DANFE --> Cancel[POST /nfe/cancelamento]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/nfe/modelo/config` | Returns JSON template for ACBr NFe configuration parameters |
| `GET` | `/nfe/modelo/nfe` | Returns JSON template for NFe document schema |
| `POST` | `/nfe/status` | Checks SEFAZ service status for specified state (UF) |
| `POST` | `/nfe/danfe` | Renders DANFE from NFe XML string into Base64 PDF |
| `POST` | `/nfe/eventos` | Transmits NFe event (CC-e, Manifestação) to SEFAZ |
| `POST` | `/nfe/distribuicao` | Queries NSU distribution list from SEFAZ |
| `POST` | `/nfe/cancelamento` | Cancels an authorized NFe document |
| `POST` | `/nfe/inutilizacao` | Inutilizes a gap of NFe invoice numbers |

## Related Pages
- [[ACBRWebService_Architecture]]
- [[route-acbr-nfe]]
- [[ACBr]]
- [[Horse_Framework]]
