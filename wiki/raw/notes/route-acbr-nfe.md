---
title: Route ACBr NFe Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.nfe.pas
  - method/method.acbr.nfe.pas
tags:
  - nfe
  - routes
  - rest-api
---

# Route ACBr NFe (unit route.acbr.nfe)

Defines Horse REST API endpoints for Electronic Fiscal Invoice (NFe - Nota Fiscal Eletrônica).

## Key HTTP Handlers

- `GET /nfe/modelo/config` — Returns sample JSON configuration model for ACBr NFe.
- `GET /nfe/modelo/nfe` — Returns sample JSON schema for NFe submission.
- `POST /nfe/emitir` / `POST /nfe` — Submits NFe to SEFAZ and returns authorization result.
- `POST /nfe/danfe` — Generates DANFE PDF in Base64 from NFe XML.
- `POST /nfe/eventos` — Sends NFe events (Carta de Correção, Manifestação do Destinatário).
- `POST /nfe/distribuicao` — Queries NSU distribution of NFe documents from SEFAZ.
- `POST /nfe/cancelamento` — Cancels an authorized NFe.
- `POST /nfe/inutilizacao` — Inutilizes a range of NFe numbers.
- `POST /nfe/status` — Checks SEFAZ service status for the selected UF.
