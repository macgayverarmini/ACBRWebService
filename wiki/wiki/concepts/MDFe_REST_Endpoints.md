---
title: MDFe REST Endpoints & Pipeline
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-mdfe.md
tags:
  - mdfe
  - endpoints
  - pipeline
---

# MDFe REST Endpoints & Pipeline

The **MDFe REST Pipeline** handles cargo manifests (Modelo 58) for multi-modal transportation in Brazil via [[entities/ACBr]].

```mermaid
flowchart TD
    Config[GET /mdfe/modelo/config] --> Submit[POST /mdfe/enviar]
    Submit --> SEFAZ{SEFAZ Processing}
    SEFAZ -->|Authorized| DAMDFE[POST /mdfe/damdfe (DAMDFE PDF)]
    DAMDFE --> Event[POST /mdfe/eventos (Encerramento / Condutor)]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/mdfe/modelo/config` | JSON schema for MDFe configuration |
| `GET` | `/mdfe/modelo/mdfe` | JSON schema for MDFe cargo manifest submission |
| `POST` | `/mdfe/enviar` | Submits MDFe cargo manifest to SEFAZ |
| `POST` | `/mdfe/damdfe` | Renders DAMDFE PDF from MDFe XML into Base64 |
| `POST` | `/mdfe/eventos` | Transmits MDFe encerramento, cancellation, or driver addition event |

## Related Pages
- [[ACBRWebService_Architecture]]
- [[route-acbr-mdfe]]
- [[CTe_REST_Endpoints]]
- [[ACBr]]
