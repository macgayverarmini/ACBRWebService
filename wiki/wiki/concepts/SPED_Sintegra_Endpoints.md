---
title: SPED & Sintegra Fiscal Endpoints
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-sped-sintegra.md
tags:
  - sped
  - sintegra
  - fiscal-reporting
---

# SPED & Sintegra Fiscal Endpoints

The **SPED & Sintegra Module** generates mandatory tax auditing text files (SPED EFD Fiscal, EFD Contribuições, and Sintegra ICMS/ISS) using [[entities/ACBr]] components.

```mermaid
flowchart LR
    Client[HTTP Client] -->|POST /sped/gerar| Horse[[Horse_Framework]]
    Horse --> ACBrSPED[[ACBr]]
    ACBrSPED --> TextFile[SPED EFD Text File String]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/sped/modelo/config` | JSON schema for SPED EFD configuration |
| `POST` | `/sped/gerar` | Generates SPED EFD text output |
| `GET` | `/sintegra/modelo/config` | JSON schema for Sintegra configuration |
| `POST` | `/sintegra/gerar` | Generates Sintegra ICMS/ISS text file output |

## Related Pages
- [[ACBRWebService_Architecture]]
- [[route-acbr-sped-sintegra]]
- [[ACBr]]
