---
title: Digital Certificate Management
type: concept
created: 2026-07-28
updated: 2026-07-28
sources:
  - raw/notes/route-acbr-certificados.md
tags:
  - certificados
  - a1
  - ssl
---

# Digital Certificate Management

The **Digital Certificate Management** module allows uploading, storing, and reading ICP-Brasil A1 PFX digital certificates over HTTP endpoints.

```mermaid
flowchart LR
    Client[HTTP Client] -->|POST /certificado/upload| Bridge[ACBrCertificados Bridge]
    Bridge --> PFXStorage[Secure PFX Storage]
    Client -->|POST /certificado/ler| ReadInfo[Certificate Metadata Reader]
    ReadInfo --> ResponseJSON[CNPJ, Expiry Date, Serial, Subject JSON]
```

## Route Specifications

| Method | Endpoint Path | Description |
|--------|--------------|-------------|
| `GET` | `/certificado/modelo/upload` | JSON template for uploading A1 PFX certificate |
| `POST` | `/certificado/upload` | Uploads PFX file payload and password |
| `POST` | `/certificado/ler` | Parses certificate details without saving |

## Related Pages
- [[ACBRWebService_Architecture]]
- [[route-acbr-certificados]]
- [[NFe_REST_Endpoints]]
- [[ACBr]]
