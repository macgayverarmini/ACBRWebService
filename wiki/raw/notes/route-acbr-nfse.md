---
title: Route ACBr NFSe Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.nfse.pas
  - method/method.acbr.nfse.pas
tags:
  - nfse
  - routes
  - rest-api
---

# Route ACBr NFSe (unit route.acbr.nfse)

Defines Horse REST API endpoints for Nota Fiscal de Serviços Eletrônica (NFSe - Municipal Services).

## Key HTTP Handlers

- `GET /nfse/modelo/config` — Sample JSON configuration for ACBr NFSe provider.
- `GET /nfse/modelo/emitir` — Sample JSON payload for RPS / NFSe emission.
- `POST /nfse/emitir` — Emits NFSe / RPS batch to municipal provider.
- `POST /nfse/consultarsituacao` — Queries status of submitted RPS batch.
- `POST /nfse/consultarlote` — Queries processed batch details and return codes.
- `POST /nfse/cancelar` — Cancels an issued NFSe.
- `POST /nfse/danfse` — Generates DANFSe PDF in Base64.
