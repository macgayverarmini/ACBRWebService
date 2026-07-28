---
title: Route ACBr CTe Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.cte.pas
  - method/method.acbr.cte.pas
tags:
  - cte
  - routes
  - rest-api
---

# Route ACBr CTe (unit route.acbr.cte)

Defines Horse REST API endpoints for Conhecimento de Transporte Eletrônico (CTe - Modelo 57).

## Key HTTP Handlers

- `GET /cte/modelo/config` — Sample JSON configuration for ACBr CTe.
- `GET /cte/modelo/cte` — Sample JSON model for CTe submission.
- `POST /cte` / `POST /cte/emitir` — Submits CTe to SEFAZ and retrieves authorization status.
- `POST /cte/dacte` — Renders DACTE PDF from CTe XML in Base64.
- `POST /cte/eventos` — Transmits CTe events (Carta de Correção, Cancelamento).
- `POST /cte/inutilizacao` — Inutilizes range of CTe numbers.
- `POST /cte/status` — Queries CTe SEFAZ service status.
