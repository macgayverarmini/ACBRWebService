---
title: SPED & Sintegra Routes Unit Overview
type: note
created: 2026-07-28
updated: 2026-07-28
sources:
  - routes/route.acbr.sped.pas
  - routes/route.acbr.sintegra.pas
tags:
  - sped
  - sintegra
  - fiscal-reporting
---

# SPED & Sintegra Routes (units route.acbr.sped & route.acbr.sintegra)

Defines Horse REST API endpoints for generating mandatory Brazilian state and federal fiscal audit text files (SPED EFD Fiscal / Contribuições and Sintegra).

## Key HTTP Handlers

- `GET /sped/modelo/config` — Sample JSON schema for SPED EFD configuration.
- `POST /sped/gerar` — Generates SPED EFD text file contents.
- `GET /sintegra/modelo/config` — Sample JSON schema for Sintegra configuration.
- `POST /sintegra/gerar` — Generates Sintegra ICMS/ISS file contents.
