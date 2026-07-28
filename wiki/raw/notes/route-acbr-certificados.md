---
title: Route ACBr Certificados Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.certificados.pas
  - method/method.acbr.certificados.pas
tags:
  - certificados
  - a1
  - a3
  - ssl
---

# Route ACBr Certificados (unit route.acbr.certificados)

Defines Horse REST API endpoints for A1/A3 Digital Certificates management and PFX payload parsing.

## Key HTTP Handlers

- `GET /certificado/modelo/upload` — Sample JSON model for uploading A1 PFX certificate files.
- `POST /certificado/upload` — Stores PFX digital certificate securely.
- `POST /certificado/ler` — Reads digital certificate metadata (CNPJ, validity dates, subject, issuer, serial number).
