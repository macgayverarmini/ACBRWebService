---
title: CTe REST Endpoints & Pipeline
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-cte.md
tags:
  - cte
  - endpoints
  - pipeline
---

# CTe REST Endpoints & Pipeline

The **CTe REST Pipeline** in ACBRWebService handles freight transport invoices (Modelo 57) via [[entities/ACBr]] components.

```mermaid
flowchart TD
    Config[GET /cte/modelo/config] --> Submit[POST /cte (Emission)]
    Submit --> SEFAZ{SEFAZ Processing}
    SEFAZ -->|Authorized| DACTE[POST /cte/dacte (DACTE PDF Generation)]
    SEFAZ -->|Error| Inutilize[POST /cte/inutilizacao]
    DACTE --> Event[POST /cte/eventos (Correction/Cancel)]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/modelo/cte/config` | JSON schema for CTe configuration |
| `GET` | `/modelo/cte/cte` | JSON schema for CTe payload |
| `POST` | `/cte/status` | Queries SEFAZ transport service status |
| `POST` | `/cte` | Submits CTe transport invoice to SEFAZ |
| `POST` | `/cte/dacte` | Renders DACTE PDF from CTe XML into Base64 & download URL |
| `POST` | `/cte/dacte-url` | Lightweight rendering returning download URL & key without Base64 payload |
| `GET`  | `/cte/pdf/:chave` | Downloads binary DACTE PDF for given key |
| `POST` | `/cte/dacte-evento` | Renders DACTE event PDF (Cancelation / Correction) |
| `POST` | `/cte/eventos` | Transmits CTe correction letter or cancellation event |
| `POST` | `/cte/inutilizacao` | Inutilizes range of CTe invoice numbers |

## Related Pages
- [[DACTE_Auxiliary_Document]]
- [[ACBRWebService_Architecture]]
- [[route-acbr-cte]]
- [[NFe_REST_Endpoints]]
- [[ACBr]]

