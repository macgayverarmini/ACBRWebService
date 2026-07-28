---
title: Route ACBr MDFe Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.mdfe.pas
  - method/method.acbr.mdfe.pas
tags:
  - mdfe
  - routes
  - rest-api
---

# Route ACBr MDFe (unit route.acbr.mdfe)

Defines Horse REST API endpoints for Manifesto Eletrônico de Documentos Fiscais (MDFe - Modelo 58).

## Key HTTP Handlers

- `GET /mdfe/modelo/config` — Returns sample JSON configuration for ACBr MDFe.
- `GET /mdfe/modelo/mdfe` — Returns sample JSON schema for MDFe submission.
- `POST /mdfe/enviar` — Transmits MDFe cargo manifest to SEFAZ.
- `POST /mdfe/damdfe` — Generates DAMDFE PDF in Base64.
- `POST /mdfe/eventos` — Transmits MDFe events (Encerramento, Cancelamento, Inclusão de Condutor).
- `POST /mdfe/distribuicao` — Queries MDFe distribution list from SEFAZ.
